import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrozen/config/theme.dart';
import 'package:agrozen/data/models/weather_data.dart';
import 'package:agrozen/presentation/widgets/weather_scene.dart';
import 'package:agrozen/presentation/widgets/weather_summary_card.dart';
import 'package:agrozen/services/weather_service.dart';

/// The weather card must show the sky that is really there: from the WMO
/// code, day or night, never inferred from temperature.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sky from WMO code', () {
    test('a clear, cold morning is a clear sky, not snow', () {
      expect(WeatherService.mapWeatherCode(0, 4), 'cold');
      expect(weatherSkyFor(0, 'cold'), WeatherSky.clear);
      expect(weatherSkyFor(0, 'hot'), WeatherSky.clear);
    });

    test('every WMO group maps to its own sky', () {
      expect(weatherSkyFor(2, 'partly_cloudy'), WeatherSky.partlyCloudy);
      expect(weatherSkyFor(3, 'cloudy'), WeatherSky.overcast);
      expect(weatherSkyFor(45, 'fog'), WeatherSky.fog);
      expect(weatherSkyFor(51, 'rain'), WeatherSky.rain);
      expect(weatherSkyFor(81, 'rain'), WeatherSky.rain);
      expect(weatherSkyFor(73, 'snow'), WeatherSky.snow);
      expect(weatherSkyFor(86, 'snow'), WeatherSky.snow);
      expect(weatherSkyFor(95, 'thunderstorm'), WeatherSky.storm);
    });

    test('fog has its own condition and label', () {
      expect(WeatherService.mapWeatherCode(45, 12), 'fog');
      final fog = WeatherData(
        district: 'Namangan',
        temperature: 12,
        humidity: 95,
        windSpeed: 2,
        condition: 'fog',
        timestamp: DateTime(2026, 10, 13),
      );
      expect(fog.getConditionText('en'), 'Fog');
      expect(fog.getConditionText('ru'), 'Туман');
      expect(fog.getConditionText('uz'), 'Tuman');
    });

    test('without a code (offline estimate) the condition string decides', () {
      expect(weatherSkyFor(null, 'rain'), WeatherSky.rain);
      expect(weatherSkyFor(null, 'cold'), WeatherSky.clear);
    });
  });

  group('Day and night', () {
    final weather = WeatherData(
      district: 'Namangan',
      temperature: 17,
      humidity: 69,
      windSpeed: 2,
      condition: 'clear',
      timestamp: DateTime(2026, 10, 13, 9),
      weatherCode: 0,
      sunrise: DateTime(2026, 10, 13, 6, 22),
      sunset: DateTime(2026, 10, 13, 17, 36),
    );

    test('uses real sunrise and sunset, even from a cached reading', () {
      expect(weather.isDayAt(DateTime(2026, 10, 13, 6, 10)), isFalse);
      expect(weather.isDayAt(DateTime(2026, 10, 13, 12)), isTrue);
      expect(weather.isDayAt(DateTime(2026, 10, 13, 18)), isFalse);
      // Next day, the same cache still flips at about the same times.
      expect(weather.isDayAt(DateTime(2026, 10, 14, 18)), isFalse);
    });

    test('code, sunrise and sunset survive the cache round-trip', () {
      final back = WeatherData.fromJson(
        jsonDecode(jsonEncode(weather.toJson())) as Map<String, dynamic>,
      );
      expect(back.weatherCode, 0);
      expect(back.sunset!.hour, 17);
      expect(back.sunset!.minute, 36);
    });
  });

  test('service reads code, sunrise/sunset, daily humidity and rain chance',
      () async {
    SharedPreferences.setMockInitialValues({});
    final client = MockClient((request) async {
      expect(request.url.query, contains('sunrise'));
      expect(request.url.query, contains('precipitation_probability_max'));
      return http.Response(
        jsonEncode({
          'current': {
            'temperature_2m': 17.2,
            'relative_humidity_2m': 69,
            'apparent_temperature': 17.3,
            'weather_code': 45,
            'wind_speed_10m': 1.5,
          },
          'daily': {
            'weather_code': [3, 95, 51, 0, 1, 51],
            'temperature_2m_max': [25.1, 17.5, 20.9, 20.8, 21.5, 22.7],
            'temperature_2m_min': [14.0, 13.8, 12.4, 10.2, 12.9, 12.9],
            'wind_speed_10m_max': [11.5, 8.9, 7.7, 8.4, 9.8, 9.6],
            'relative_humidity_2m_mean': [51, 84, 79, 76, 71, 63],
            'precipitation_probability_max': [0, 65, 38, 0, 12, 10],
            'sunrise': [
              '2026-10-11T06:20', '2026-10-12T06:21', '2026-10-13T06:22',
              '2026-10-14T06:23', '2026-10-15T06:24', '2026-10-16T06:25',
            ],
            'sunset': [
              '2026-10-11T17:39', '2026-10-12T17:38', '2026-10-13T17:36',
              '2026-10-14T17:34', '2026-10-15T17:33', '2026-10-16T17:31',
            ],
          },
        }),
        200,
      );
    });

    final w = await WeatherService(client: client).getDistrictWeather('Namangan');
    expect(w.isLive, isTrue);
    expect(w.condition, 'fog');
    expect(w.sky, WeatherSky.fog);
    expect(w.sunrise, DateTime(2026, 10, 13, 6, 22));
    expect(w.sunset, DateTime(2026, 10, 13, 17, 36));

    final tomorrow = w.forecastForOffset(1);
    expect(tomorrow.sky, WeatherSky.clear);
    expect(tomorrow.humidity, 76); // real daily mean, not a guess
    expect(tomorrow.precipChance, 0);
    expect(w.forecastForOffset(0).precipChance, 38);
    expect(w.forecastForOffset(-1).sky, WeatherSky.storm);
  });

  testWidgets('card draws the scene and never shows snow for a clear cold day',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: WeatherSummaryCard(
            district: 'Namangan',
            locationLabel: 'Namangan',
            batchDay: 7,
            targetHouseTemp: 29.5,
            language: 'en',
            loader: (d) async => WeatherData(
              district: d,
              temperature: 3,
              humidity: 70,
              windSpeed: 4,
              condition: 'cold',
              weatherCode: 0,
              timestamp: DateTime.now(),
              isLive: true,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final scene = tester.widget<WeatherScene>(find.byType(WeatherScene));
    expect(scene.sky, WeatherSky.clear);
    expect(find.text('3°'), findsOneWidget);
    expect(find.text('Outside 3°C'), findsOneWidget);
    expect(find.text('Barn 29.5°C'), findsOneWidget);
    expect(find.byIcon(Icons.ac_unit_rounded), findsNothing);
  });
}
