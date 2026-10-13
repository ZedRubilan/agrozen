import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/weather_data.dart';

/// Regional weather service for poultry farmers across all 13 regions of Uzbekistan.
///
/// Fetches free real-time weather and 6-day forecast (D-2 through D+3) from Open-Meteo
/// using either the farmer's exact GPS coordinates or regional coordinates,
/// and caches data locally in SharedPreferences with regional fallback when offline.
class WeatherService {
  static final http.Client _sharedClient = http.Client();
  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? _sharedClient;

  static const Map<String, ({double lat, double lon})> districtCoordinates = {
    'Toshkent': (lat: 41.3111, lon: 69.2797),
    'Samarqand': (lat: 39.6542, lon: 66.9597),
    'Buxoro': (lat: 39.7747, lon: 64.4286),
    'Andijon': (lat: 40.7821, lon: 72.3442),
    "Farg'ona": (lat: 40.3842, lon: 71.7843),
    'Namangan': (lat: 40.9983, lon: 71.6726),
    'Qashqadaryo': (lat: 38.8606, lon: 65.7891),
    'Surxondaryo': (lat: 37.2242, lon: 67.2783),
    'Jizzax': (lat: 40.1158, lon: 67.8422),
    'Sirdaryo': (lat: 40.4897, lon: 68.7842),
    'Xorazm': (lat: 41.5500, lon: 60.6333),
    'Navoiy': (lat: 40.0844, lon: 65.3792),
    "Qoraqalpog'iston": (lat: 42.4602, lon: 59.6166),
  };

  /// Fetch weather for the farmer's district.
  Future<WeatherData> getWeatherForDistrict(
    String district, {
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      // Clear cache for this district to force fresh API call
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('weather_cache_$district');
        await prefs.remove('weather_$district');
      } catch (_) {}
    }
    return getDistrictWeather(district);
  }

  /// Fetch weather for the farmer's district (using exact GPS or town coordinates when
  /// saved for this district, or the district's canonical coordinates).
  Future<WeatherData> getDistrictWeather(String district) async {
    String? savedLocality;
    double? customLat;
    double? customLon;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDistrict = prefs.getString('farmer_district');
      final loc = prefs.getString('farmer_locality');
      final savedLat = prefs.getDouble('farmer_lat');
      final savedLon = prefs.getDouble('farmer_lon');
      if (savedDistrict == district) {
        savedLocality = loc;
        if (savedLat != null && savedLon != null) {
          customLat = savedLat;
          customLon = savedLon;
        }
      }
    } catch (_) {}

    // 1. Try local cache if fresh (< 2 hours old) and matching locality
    try {
      final cached = await _getCachedWeather(district);
      if (cached != null) {
        final age = DateTime.now().difference(cached.timestamp);
        final localityMatches =
            savedLocality == null || cached.locality == savedLocality;
        if (age.inHours < 2 && localityMatches) {
          return cached;
        }
      }
    } catch (_) {}

    // 2. Resolve coordinates (exact GPS / town override if saved for this district, else canonical)
    final defaultCoords =
        districtCoordinates[district] ?? districtCoordinates['Toshkent']!;
    final double lat = customLat ?? defaultCoords.lat;
    final double lon = customLon ?? defaultCoords.lon;

    // 3. Fetch live current + 6-day forecast data from Open-Meteo
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?'
      'latitude=$lat&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,wind_speed_10m_max,'
      'relative_humidity_2m_mean,precipitation_probability_max,sunrise,sunset'
      '&past_days=2&forecast_days=4'
      '&timezone=Asia%2FTashkent',
    );

    try {
      final response =
          await _client.get(url).timeout(const Duration(milliseconds: 8000));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final current = data['current'] as Map<String, dynamic>?;

        if (current != null) {
          final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 24.0;
          final hum = (current['relative_humidity_2m'] as num?)?.toInt() ?? 45;
          final feelsLike =
              (current['apparent_temperature'] as num?)?.toDouble() ?? temp;
          final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 10.0;
          final code = (current['weather_code'] as num?)?.toInt() ?? 0;

          final condition = mapWeatherCode(code, temp);
          final daily = data['daily'] as Map<String, dynamic>?;
          final dailyForecast = _parseDailyForecast(
            daily,
            baseTemp: temp,
            baseHumidity: hum,
            baseWind: wind,
            baseCondition: condition,
          );

          final weather = WeatherData(
            district: district,
            locality: savedLocality,
            temperature: temp,
            humidity: hum,
            windSpeed: wind,
            condition: condition,
            timestamp: DateTime.now(),
            feelsLike: feelsLike,
            latitude: lat,
            longitude: lon,
            isLive: true,
            dailyForecast: dailyForecast,
            weatherCode: code,
            sunrise: _todayTime(daily, 'sunrise'),
            sunset: _todayTime(daily, 'sunset'),
          );

          await _cacheWeather(district, weather);
          return weather;
        }
      }
    } catch (e) {
      debugPrint('WeatherService network notice: $e');
    }

    // 4. Fallback to cached or regional seasonal default
    try {
      final stale = await _getCachedWeather(district);
      if (stale != null) return stale;
    } catch (_) {}

    return WeatherData.fallback(district, locality: savedLocality);
  }

  static List<WeatherForecastDay> _parseDailyForecast(
    Map<String, dynamic>? daily, {
    required double baseTemp,
    required int baseHumidity,
    required double baseWind,
    required String baseCondition,
  }) {
    if (daily == null) {
      return WeatherData.buildSynthesizedForecast(
        baseTemp: baseTemp,
        baseHumidity: baseHumidity,
        baseWind: baseWind,
        baseCondition: baseCondition,
      );
    }

    try {
      final maxTemps = daily['temperature_2m_max'] as List?;
      final minTemps = daily['temperature_2m_min'] as List?;
      final codes = daily['weather_code'] as List?;
      final winds = daily['wind_speed_10m_max'] as List?;
      final hums = daily['relative_humidity_2m_mean'] as List?;
      final rainChances = daily['precipitation_probability_max'] as List?;
      num? at(List? list, int i) =>
          (list != null && i < list.length) ? list[i] as num? : null;

      if (maxTemps != null && minTemps != null && maxTemps.length >= 6) {
        final result = <WeatherForecastDay>[];
        for (int i = 0; i < 6; i++) {
          final dayOffset = i - 2; // -2, -1, 0, +1, +2, +3
          final maxT = (maxTemps[i] as num?)?.toDouble() ?? baseTemp + 3;
          final minT = (minTemps[i] as num?)?.toDouble() ?? baseTemp - 3;
          final avgT =
              dayOffset == 0 ? baseTemp : (maxT * 0.75 + minT * 0.25);
          final wCode = (codes != null && i < codes.length)
              ? ((codes[i] as num?)?.toInt() ?? 0)
              : 0;
          final wSpeed = (winds != null && i < winds.length)
              ? ((winds[i] as num?)?.toDouble() ?? baseWind)
              : baseWind;
          result.add(
            WeatherForecastDay(
              dayOffset: dayOffset,
              tempMax: maxT,
              tempMin: minT,
              tempAvg: avgT,
              humidity: dayOffset == 0
                  ? baseHumidity
                  : (at(hums, i)?.round() ??
                      (baseHumidity + (dayOffset * -2)).clamp(20, 92)),
              windSpeed: wSpeed,
              condition: mapWeatherCode(wCode, avgT),
              weatherCode: wCode,
              precipChance: at(rainChances, i)?.round(),
            ),
          );
        }
        return result;
      }
    } catch (_) {}

    return WeatherData.buildSynthesizedForecast(
      baseTemp: baseTemp,
      baseHumidity: baseHumidity,
      baseWind: baseWind,
      baseCondition: baseCondition,
    );
  }

  /// Today's (index 2: past_days=2) sunrise or sunset from the daily block.
  static DateTime? _todayTime(Map<String, dynamic>? daily, String key) {
    final list = daily?[key] as List?;
    if (list == null || list.length < 3) return null;
    return DateTime.tryParse(list[2]?.toString() ?? '');
  }

  /// WMO weather code → condition string used in advice and AI prompts.
  /// Only a clear sky (code 0) is labelled 'hot' / 'cold' by temperature;
  /// the weather scene reads the code itself via [WeatherData.sky].
  static String mapWeatherCode(int code, double temp) {
    if (code == 45 || code == 48) return 'fog';
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return 'rain';
    }
    if (code >= 71 && code <= 86) return 'snow';
    if (code >= 95) return 'thunderstorm';
    if (code == 1 || code == 2) return 'partly_cloudy';
    if (code >= 3) return 'cloudy';
    if (temp >= 32.0) return 'hot';
    if (temp <= 10.0) return 'cold';
    return 'clear';
  }

  Future<void> _cacheWeather(String district, WeatherData weather) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'weather_cache_$district',
        jsonEncode(weather.toJson()),
      );
    } catch (_) {}
  }

  Future<WeatherData?> _getCachedWeather(String district) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('weather_cache_$district');
      if (str != null) {
        final decoded = jsonDecode(str) as Map<String, dynamic>;
        return WeatherData.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }
}
