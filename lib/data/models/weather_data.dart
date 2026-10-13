import 'package:equatable/equatable.dart';

/// What the sky actually looks like — drives the weather scene. Unlike
/// `condition`, it never mixes in temperature ('hot' / 'cold' are clear skies).
enum WeatherSky { clear, partlyCloudy, overcast, fog, rain, snow, storm }

/// WMO weather code (Open-Meteo) → sky, or the legacy `condition` string
/// when no code is stored (offline estimate, old cache).
WeatherSky weatherSkyFor(int? code, String condition) {
  if (code != null) {
    if (code == 0) return WeatherSky.clear;
    if (code == 1 || code == 2) return WeatherSky.partlyCloudy;
    if (code == 3) return WeatherSky.overcast;
    if (code == 45 || code == 48) return WeatherSky.fog;
    if (code >= 95) return WeatherSky.storm;
    if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
      return WeatherSky.snow;
    }
    if (code >= 51 && code <= 82) return WeatherSky.rain;
    return WeatherSky.overcast;
  }
  switch (condition) {
    case 'partly_cloudy':
      return WeatherSky.partlyCloudy;
    case 'cloudy':
      return WeatherSky.overcast;
    case 'fog':
      return WeatherSky.fog;
    case 'rain':
      return WeatherSky.rain;
    case 'snow':
      return WeatherSky.snow;
    case 'thunderstorm':
      return WeatherSky.storm;
    default: // clear, hot, cold
      return WeatherSky.clear;
  }
}

/// Represents a single day's outdoor weather summary (for D-2 through D+3).
class WeatherForecastDay extends Equatable {
  final int dayOffset; // -2, -1, 0 (Today), +1, +2, +3
  final double tempMax;
  final double tempMin;
  final double tempAvg;
  final int humidity;
  final double windSpeed;
  final String condition;

  /// WMO code from the API; null for synthesized days.
  final int? weatherCode;

  /// Highest chance of rain/snow that day, %; null when unknown.
  final int? precipChance;

  const WeatherForecastDay({
    required this.dayOffset,
    required this.tempMax,
    required this.tempMin,
    required this.tempAvg,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    this.weatherCode,
    this.precipChance,
  });

  WeatherSky get sky => weatherSkyFor(weatherCode, condition);

  factory WeatherForecastDay.fromJson(Map<String, dynamic> json) {
    final maxT = (json['temp_max'] as num?)?.toDouble() ?? 25.0;
    final minT = (json['temp_min'] as num?)?.toDouble() ?? 15.0;
    return WeatherForecastDay(
      dayOffset: (json['day_offset'] as num?)?.toInt() ?? 0,
      tempMax: maxT,
      tempMin: minT,
      tempAvg: (json['temp_avg'] as num?)?.toDouble() ?? ((maxT + minT) / 2.0),
      humidity: (json['humidity'] as num?)?.toInt() ?? 45,
      windSpeed: (json['wind_speed'] as num?)?.toDouble() ?? 10.0,
      condition: json['condition'] as String? ?? 'clear',
      weatherCode: (json['weather_code'] as num?)?.toInt(),
      precipChance: (json['precip_chance'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'day_offset': dayOffset,
        'temp_max': tempMax,
        'temp_min': tempMin,
        'temp_avg': tempAvg,
        'humidity': humidity,
        'wind_speed': windSpeed,
        'condition': condition,
        if (weatherCode != null) 'weather_code': weatherCode,
        if (precipChance != null) 'precip_chance': precipChance,
      };

  @override
  List<Object?> get props => [
        dayOffset,
        tempMax,
        tempMin,
        tempAvg,
        humidity,
        windSpeed,
        condition,
        weatherCode,
        precipChance,
      ];
}

class WeatherData extends Equatable {
  final String district;
  final String? locality;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final String condition;
  final DateTime timestamp;
  final double? feelsLike;
  final double? latitude;
  final double? longitude;
  final bool isLive;
  final List<WeatherForecastDay> dailyForecast;

  /// WMO code of the current weather; null for offline estimates.
  final int? weatherCode;

  /// Today's sunrise and sunset (local time) when the API supplied them.
  final DateTime? sunrise;
  final DateTime? sunset;

  const WeatherData({
    required this.district,
    this.locality,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.timestamp,
    this.feelsLike,
    this.latitude,
    this.longitude,
    this.isLive = false,
    this.dailyForecast = const [],
    this.weatherCode,
    this.sunrise,
    this.sunset,
  });

  WeatherSky get sky => weatherSkyFor(weatherCode, condition);

  /// Daylight right now — from today's sunrise/sunset when known (so a cached
  /// reading still flips to night on time), else 06:00–19:00.
  bool isDayAt(DateTime now) {
    final rise = sunrise;
    final set = sunset;
    if (rise != null && set != null) {
      final r = DateTime(now.year, now.month, now.day, rise.hour, rise.minute);
      final s = DateTime(now.year, now.month, now.day, set.hour, set.minute);
      return !now.isBefore(r) && now.isBefore(s);
    }
    return now.hour >= 6 && now.hour < 19;
  }

  /// Regional climate modifiers across Uzbekistan's 13 provinces and key foothill districts
  /// so each area reflects its true geographic microclimate (temp offset °C, humidity offset %, wind km/h).
  static const Map<String, ({double tempDelta, int humDelta, double wind, String condHint})>
      _regionalOffsets = {
    'Toshkent': (tempDelta: 0.0, humDelta: 0, wind: 11.0, condHint: 'clear'),
    'Samarqand': (tempDelta: -0.5, humDelta: 3, wind: 10.0, condHint: 'partly_cloudy'),
    'Buxoro': (tempDelta: 3.5, humDelta: -10, wind: 15.0, condHint: 'clear'),
    'Andijon': (tempDelta: 0.5, humDelta: 6, wind: 8.5, condHint: 'partly_cloudy'),
    "Farg'ona": (tempDelta: 1.0, humDelta: 5, wind: 9.0, condHint: 'clear'),
    'Namangan': (tempDelta: 0.8, humDelta: 4, wind: 9.5, condHint: 'clear'),
    'Chortoq': (tempDelta: 0.4, humDelta: -3, wind: 6.5, condHint: 'clear'),
    'Qashqadaryo': (tempDelta: 3.0, humDelta: -8, wind: 13.0, condHint: 'clear'),
    'Surxondaryo': (tempDelta: 4.5, humDelta: -12, wind: 14.0, condHint: 'hot'),
    'Jizzax': (tempDelta: 1.2, humDelta: -3, wind: 12.5, condHint: 'clear'),
    'Sirdaryo': (tempDelta: 1.5, humDelta: -2, wind: 13.5, condHint: 'clear'),
    'Xorazm': (tempDelta: -1.5, humDelta: -6, wind: 16.0, condHint: 'partly_cloudy'),
    'Navoiy': (tempDelta: 2.5, humDelta: -9, wind: 15.5, condHint: 'clear'),
    "Qoraqalpog'iston": (tempDelta: -3.0, humDelta: -8, wind: 18.0, condHint: 'cloudy'),
  };

  factory WeatherData.fallback(String district, {String? locality}) {
    final now = DateTime.now();
    double baseTemp = 22.0;
    int baseHum = 50;

    if (now.month >= 6 && now.month <= 8) {
      baseTemp = 34.0;
      baseHum = 30;
    } else if (now.month >= 11 || now.month <= 2) {
      baseTemp = 8.0;
      baseHum = 70;
    } else {
      baseTemp = 23.0;
      baseHum = 44;
    }

    final lookupKey = (locality != null && _regionalOffsets.containsKey(locality))
        ? locality
        : district;
    final mod = _regionalOffsets[lookupKey] ??
        _regionalOffsets[district] ??
        (tempDelta: 0.0, humDelta: 0, wind: 12.0, condHint: 'clear');
    final temp = (baseTemp + mod.tempDelta).clamp(-10.0, 45.0);
    final hum = (baseHum + mod.humDelta).clamp(20, 95);
    final wind = mod.wind;
    final cond = temp >= 31.0
        ? 'hot'
        : (temp <= 10.0 ? 'cold' : mod.condHint);

    final forecast = buildSynthesizedForecast(
      baseTemp: temp,
      baseHumidity: hum,
      baseWind: wind,
      baseCondition: cond,
    );

    return WeatherData(
      district: district,
      locality: locality,
      temperature: temp,
      humidity: hum,
      windSpeed: wind,
      condition: cond,
      timestamp: now,
      feelsLike: temp + (hum > 60 ? 1.2 : -0.6),
      isLive: false,
      dailyForecast: forecast,
    );
  }

  /// Generates a realistic 6-day forecast strip (`D-2` through `D+3`) anchored
  /// around [baseTemp] when daily forecast arrays are not supplied.
  static List<WeatherForecastDay> buildSynthesizedForecast({
    required double baseTemp,
    required int baseHumidity,
    required double baseWind,
    required String baseCondition,
  }) {
    const offsets = [-2, -1, 0, 1, 2, 3];
    const tempSwings = [-1.4, -0.6, 0.0, 0.8, 1.3, -0.5];
    const humSwings = [4, 2, 0, -3, -5, 2];

    return List.generate(offsets.length, (i) {
      final d = offsets[i];
      final avg = (baseTemp + tempSwings[i]).clamp(-15.0, 46.0);
      final maxT = (avg + 4.0).clamp(-10.0, 48.0);
      final minT = (avg - 4.5).clamp(-20.0, 40.0);
      final hum = (baseHumidity + humSwings[i]).clamp(18, 95);
      final cond = avg >= 32.0
          ? 'hot'
          : (avg <= 10.0
              ? 'cold'
              : (d == 2 && baseCondition == 'clear'
                  ? 'partly_cloudy'
                  : baseCondition));
      return WeatherForecastDay(
        dayOffset: d,
        tempMax: maxT,
        tempMin: minT,
        tempAvg: avg,
        humidity: hum,
        windSpeed: (baseWind + (i.isEven ? 1.2 : -0.8)).clamp(3.0, 35.0),
        condition: cond,
      );
    });
  }

  factory WeatherData.seasonalFallback({
    required String districtName,
    String? locality,
  }) =>
      WeatherData.fallback(districtName, locality: locality);

  String get districtName => district;

  String get conditionText => getConditionText('uz');

  /// Returns the forecast entry for [dayOffset] (`-2` to `3`), or synthesizes one.
  WeatherForecastDay forecastForOffset(int dayOffset) {
    for (final f in dailyForecast) {
      if (f.dayOffset == dayOffset) return f;
    }
    final synthesized = buildSynthesizedForecast(
      baseTemp: temperature,
      baseHumidity: humidity,
      baseWind: windSpeed,
      baseCondition: condition,
    );
    return synthesized.firstWhere(
      (f) => f.dayOffset == dayOffset,
      orElse: () => synthesized[2],
    );
  }

  String getConditionText(String lang) {
    final code = lang.trim().toLowerCase();
    final isEn = code.startsWith('en');
    final isRu = code.startsWith('ru');

    switch (condition) {
      case 'hot':
        if (isEn) return 'Hot / Sunny';
        if (isRu) return 'Жарко / Солнечно';
        return 'Issiq / Quyoshli';
      case 'cold':
        if (isEn) return 'Cold';
        if (isRu) return 'Холодно';
        return 'Sovuq';
      case 'rain':
        if (isEn) return 'Rainy';
        if (isRu) return 'Дождливо';
        return 'Yomg\'irli';
      case 'snow':
        if (isEn) return 'Snowy';
        if (isRu) return 'Снежно';
        return 'Qorli';
      case 'thunderstorm':
        if (isEn) return 'Thunderstorm';
        if (isRu) return 'Гроза';
        return 'Momaqaldiroq';
      case 'fog':
        if (isEn) return 'Fog';
        if (isRu) return 'Туман';
        return 'Tuman';
      case 'partly_cloudy':
        if (isEn) return 'Partly Cloudy';
        if (isRu) return 'Переменная облачность';
        return 'Qisman bulutli';
      case 'cloudy':
        if (isEn) return 'Cloudy';
        if (isRu) return 'Облачно';
        return 'Bulutli';
      case 'clear':
      default:
        if (isEn) return 'Clear Sky';
        if (isRu) return 'Ясно';
        return 'Ochiq havo';
    }
  }

  WeatherData copyWith({
    String? district,
    String? locality,
    double? temperature,
    int? humidity,
    double? windSpeed,
    String? condition,
    DateTime? timestamp,
    double? feelsLike,
    double? latitude,
    double? longitude,
    bool? isLive,
    List<WeatherForecastDay>? dailyForecast,
    int? weatherCode,
    DateTime? sunrise,
    DateTime? sunset,
  }) {
    return WeatherData(
      district: district ?? this.district,
      locality: locality ?? this.locality,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      condition: condition ?? this.condition,
      timestamp: timestamp ?? this.timestamp,
      feelsLike: feelsLike ?? this.feelsLike,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLive: isLive ?? this.isLive,
      dailyForecast: dailyForecast ?? this.dailyForecast,
      weatherCode: weatherCode ?? this.weatherCode,
      sunrise: sunrise ?? this.sunrise,
      sunset: sunset ?? this.sunset,
    );
  }

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final rawForecast = json['daily_forecast'];
    final parsedForecast = <WeatherForecastDay>[];
    if (rawForecast is List) {
      for (final item in rawForecast) {
        if (item is Map<String, dynamic>) {
          parsedForecast.add(WeatherForecastDay.fromJson(item));
        } else if (item is Map) {
          parsedForecast.add(
            WeatherForecastDay.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return WeatherData(
      district: json['district'] as String? ?? 'Toshkent',
      locality: json['locality'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 24.0,
      humidity: (json['humidity'] as num?)?.toInt() ?? 50,
      windSpeed: (json['wind_speed'] as num?)?.toDouble() ?? 10.0,
      condition: json['condition'] as String? ?? 'clear',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      feelsLike: (json['feels_like'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isLive: json['is_live'] as bool? ?? false,
      dailyForecast: parsedForecast,
      weatherCode: (json['weather_code'] as num?)?.toInt(),
      sunrise: DateTime.tryParse(json['sunrise'] as String? ?? ''),
      sunset: DateTime.tryParse(json['sunset'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'district': district,
        if (locality != null) 'locality': locality,
        'temperature': temperature,
        'humidity': humidity,
        'wind_speed': windSpeed,
        'condition': condition,
        'timestamp': timestamp.toIso8601String(),
        if (feelsLike != null) 'feels_like': feelsLike,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'is_live': isLive,
        if (dailyForecast.isNotEmpty)
          'daily_forecast': dailyForecast.map((f) => f.toJson()).toList(),
        if (weatherCode != null) 'weather_code': weatherCode,
        if (sunrise != null) 'sunrise': sunrise!.toIso8601String(),
        if (sunset != null) 'sunset': sunset!.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        district,
        locality,
        temperature,
        humidity,
        windSpeed,
        condition,
        timestamp,
        weatherCode,
      ];
}
