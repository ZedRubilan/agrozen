import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/weather_data.dart';

/// Regional weather service for poultry farmers across all 13 regions of Uzbekistan.
///
/// Fetches free real-time weather from Open-Meteo with zero API keys required,
/// and caches data locally in SharedPreferences with fallback when offline.
class WeatherService {
  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

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
  Future<WeatherData> getWeatherForDistrict(String district, {bool forceRefresh = false}) async {
    if (forceRefresh) {
      // Clear cache for this district to force fresh API call
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('weather_$district');
      } catch (_) {}
    }
    return getDistrictWeather(district);
  }

  /// Fetch weather for the farmer's district.
  Future<WeatherData> getDistrictWeather(String district) async {
    // 1. Try local cache if fresh (< 2 hours old)
    try {
      final cached = await _getCachedWeather(district);
      if (cached != null) {
        final age = DateTime.now().difference(cached.timestamp);
        if (age.inHours < 2) {
          return cached;
        }
      }
    } catch (_) {}

    // 2. Fetch live data
    final coords = districtCoordinates[district] ?? districtCoordinates['Toshkent']!;
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?'
      'latitude=${coords.lat}&longitude=${coords.lon}'
      '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m'
      '&timezone=Asia%2FTashkent',
    );

    try {
      final response = await _client.get(url).timeout(const Duration(milliseconds: 2500));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final current = data['current'] as Map<String, dynamic>?;

        if (current != null) {
          final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 24.0;
          final hum = (current['relative_humidity_2m'] as num?)?.toInt() ?? 45;
          final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 10.0;
          final code = (current['weather_code'] as num?)?.toInt() ?? 0;

          final condition = _mapWeatherCode(code, temp);
          final weather = WeatherData(
            district: district,
            temperature: temp,
            humidity: hum,
            windSpeed: wind,
            condition: condition,
            timestamp: DateTime.now(),
          );

          await _cacheWeather(district, weather);
          return weather;
        }
      }
    } catch (e) {
      debugPrint('WeatherService network notice: $e');
    }

    // 3. Fallback to cached or seasonal default
    try {
      final stale = await _getCachedWeather(district);
      if (stale != null) return stale;
    } catch (_) {}

    return WeatherData.fallback(district);
  }

  static String _mapWeatherCode(int code, double temp) {
    if (code >= 51 && code <= 67) return 'rain';
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
      await prefs.setString('weather_cache_$district', jsonEncode(weather.toJson()));
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
