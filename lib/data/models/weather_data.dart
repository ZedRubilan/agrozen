import 'package:equatable/equatable.dart';

/// Represents a single day's outdoor weather summary (for D-2 through D+3).
class WeatherForecastDay extends Equatable {
  final int dayOffset; // -2, -1, 0 (Today), +1, +2, +3
  final double tempMax;
  final double tempMin;
  final double tempAvg;
  final int humidity;
  final double windSpeed;
  final String condition;

  const WeatherForecastDay({
    required this.dayOffset,
    required this.tempMax,
    required this.tempMin,
    required this.tempAvg,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
  });

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
      ];
}

class WeatherData extends Equatable {
  final String district;
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

  const WeatherData({
    required this.district,
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
  });

  /// Regional climate modifiers across Uzbekistan's 13 provinces so each region
  /// reflects its true geographic microclimate (temp offset °C, humidity offset %, wind km/h).
  static const Map<String, ({double tempDelta, int humDelta, double wind, String condHint})>
      _regionalOffsets = {
    'Toshkent': (tempDelta: 0.0, humDelta: 0, wind: 11.0, condHint: 'clear'),
    'Samarqand': (tempDelta: -0.5, humDelta: 3, wind: 10.0, condHint: 'partly_cloudy'),
    'Buxoro': (tempDelta: 3.5, humDelta: -10, wind: 15.0, condHint: 'clear'),
    'Andijon': (tempDelta: 0.5, humDelta: 6, wind: 8.5, condHint: 'partly_cloudy'),
    "Farg'ona": (tempDelta: 1.0, humDelta: 5, wind: 9.0, condHint: 'clear'),
    'Namangan': (tempDelta: 0.8, humDelta: 4, wind: 9.5, condHint: 'clear'),
    'Qashqadaryo': (tempDelta: 3.0, humDelta: -8, wind: 13.0, condHint: 'clear'),
    'Surxondaryo': (tempDelta: 4.5, humDelta: -12, wind: 14.0, condHint: 'hot'),
    'Jizzax': (tempDelta: 1.2, humDelta: -3, wind: 12.5, condHint: 'clear'),
    'Sirdaryo': (tempDelta: 1.5, humDelta: -2, wind: 13.5, condHint: 'clear'),
    'Xorazm': (tempDelta: -1.5, humDelta: -6, wind: 16.0, condHint: 'partly_cloudy'),
    'Navoiy': (tempDelta: 2.5, humDelta: -9, wind: 15.5, condHint: 'clear'),
    "Qoraqalpog'iston": (tempDelta: -3.0, humDelta: -8, wind: 18.0, condHint: 'cloudy'),
  };

  factory WeatherData.fallback(String district) {
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
      baseHum = 46;
    }

    final mod = _regionalOffsets[district] ??
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

  factory WeatherData.seasonalFallback({required String districtName}) =>
      WeatherData.fallback(districtName);

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
  }) {
    return WeatherData(
      district: district ?? this.district,
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
    );
  }

  Map<String, dynamic> toJson() => {
        'district': district,
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
      };

  @override
  List<Object?> get props => [
        district,
        temperature,
        humidity,
        windSpeed,
        condition,
        timestamp,
      ];
}
