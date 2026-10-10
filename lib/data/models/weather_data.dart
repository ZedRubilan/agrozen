import 'package:equatable/equatable.dart';

class WeatherData extends Equatable {
  final String district;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final String condition;
  final DateTime timestamp;

  const WeatherData({
    required this.district,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.timestamp,
  });

  factory WeatherData.fallback(String district) {
    // Representative seasonal baseline for Uzbekistan climate
    final now = DateTime.now();
    double temp = 22.0;
    int hum = 50;

    if (now.month >= 6 && now.month <= 8) {
      temp = 34.0;
      hum = 30;
    } else if (now.month >= 11 || now.month <= 2) {
      temp = 8.0;
      hum = 70;
    } else {
      temp = 24.0;
      hum = 45;
    }

    return WeatherData(
      district: district,
      temperature: temp,
      humidity: hum,
      windSpeed: 12.0,
      condition: temp > 30 ? 'hot' : (temp < 12 ? 'cold' : 'clear'),
      timestamp: now,
    );
  }

  factory WeatherData.seasonalFallback({required String districtName}) =>
      WeatherData.fallback(districtName);

  String get districtName => district;

  String get conditionText => getConditionText('uz');

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
  }) {
    return WeatherData(
      district: district ?? this.district,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      condition: condition ?? this.condition,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      district: json['district'] as String? ?? 'Toshkent',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 24.0,
      humidity: (json['humidity'] as num?)?.toInt() ?? 50,
      windSpeed: (json['wind_speed'] as num?)?.toDouble() ?? 10.0,
      condition: json['condition'] as String? ?? 'clear',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'district': district,
        'temperature': temperature,
        'humidity': humidity,
        'wind_speed': windSpeed,
        'condition': condition,
        'timestamp': timestamp.toIso8601String(),
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
