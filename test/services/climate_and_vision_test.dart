import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrozen/data/models/weather_data.dart';
import 'package:agrozen/domain/climate/climate_advisor.dart';
import 'package:agrozen/services/location_service.dart';
import 'package:agrozen/services/poultry_vision_analyzer.dart';
import 'package:agrozen/services/tts_service.dart';
import 'package:agrozen/services/weather_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClimateAdvisor & Microclimate Guidance Tests', () {
    test('1. Detects heat stress and provides cooling & feed restrictions', () {
      final advice = ClimateAdvisor.evaluate(
        flockAgeDays: 28,
        outsideTemp: 36.0,
        outsideHumidity: 40.0,
        targetHouseTemp: 24.0,
        lang: 'uz',
      );

      expect(advice.riskLevel, ClimateRiskLevel.heatWarning);
      expect(advice.statusBadge, contains('Issiq urish xavfi'));
      expect(advice.directive, contains('Ventilyatorlarni'));
      expect(advice.ventilationAdvice, contains('Tunnel ventilyatsiya'));
      expect(advice.waterFeedAdvice, contains('elektrolit'));
    });

    test('2. Evaluates cold stress for young chicks (Day 3) in Russian', () {
      final advice = ClimateAdvisor.evaluate(
        flockAgeDays: 3,
        outsideTemp: 5.0,
        outsideHumidity: 60.0,
        targetHouseTemp: 33.0,
        lang: 'ru',
      );

      expect(advice.riskLevel, ClimateRiskLevel.coldWarning);
      expect(advice.statusBadge, contains('Риск переохлаждения'));
      expect(advice.directive, contains('Маленькие цыплята очень чувствительны к холоду'));
      expect(advice.waterFeedAdvice, contains('не ниже 18-20°C'));
    });

    test('3. Detects high humidity and ammonia hazard in English', () {
      final advice = ClimateAdvisor.evaluate(
        flockAgeDays: 20,
        outsideTemp: 25.0,
        outsideHumidity: 82.0,
        targetHouseTemp: 26.0,
        lang: 'en',
      );

      expect(advice.riskLevel, ClimateRiskLevel.highHumidityRisk);
      expect(advice.statusBadge, contains('High Humidity'));
      expect(advice.directive, contains('ventilation rate to exhaust moisture'));
      expect(advice.ventilationAdvice, contains('ventilation'));
    });

    test('4. Detects optimal microclimate conditions', () {
      final advice = ClimateAdvisor.evaluate(
        flockAgeDays: 14,
        outsideTemp: 28.0,
        outsideHumidity: 55.0,
        targetHouseTemp: 28.0,
        lang: 'uz',
      );

      expect(advice.riskLevel, ClimateRiskLevel.optimal);
      expect(advice.statusBadge, contains('Qulay mikroklimat'));
    });

    test('4b. On Day 2 (targetHouseTemp: 33.5°C, outsideTemp: 32.0°C, diff = -1.5°C), does NOT falsely trigger heatWarning or tunnel ventilation', () {
      final advice = ClimateAdvisor.evaluate(
        flockAgeDays: 2,
        outsideTemp: 32.0,
        outsideHumidity: 55.0,
        targetHouseTemp: 33.5,
        lang: 'uz',
      );

      expect(advice.tempDifference, closeTo(-1.5, 0.01));
      expect(advice.riskLevel, isNot(ClimateRiskLevel.heatWarning));
      expect(advice.riskLevel, ClimateRiskLevel.optimal);
      expect(advice.ventilationAdvice, isNot(contains('1.5-2.5 m/s')));
      expect(advice.ventilationAdvice, isNot(contains('Tunnel ventilyatsiya')));
    });
  });

  group('WeatherData & WeatherService Tests', () {
    test('5. WeatherData fallback generates representative seasonal climate for Uzbekistan', () {
      final fallback = WeatherData.fallback('Samarqand');
      expect(fallback.district, 'Samarqand');
      expect(fallback.temperature, inInclusiveRange(-10.0, 45.0));
      expect(fallback.humidity, inInclusiveRange(20, 95));
      expect(fallback.districtName, 'Samarqand');
      expect(fallback.conditionText, isNotEmpty);
    });

    test('6. WeatherData JSON serialization round-trip', () {
      final now = DateTime.now();
      final data = WeatherData(
        district: 'Buxoro',
        temperature: 31.5,
        humidity: 35,
        windSpeed: 14.2,
        condition: 'hot',
        timestamp: now,
      );

      final json = data.toJson();
      final recovered = WeatherData.fromJson(json);

      expect(recovered.district, 'Buxoro');
      expect(recovered.temperature, 31.5);
      expect(recovered.humidity, 35);
      expect(recovered.condition, 'hot');
    });

    test('7. WeatherService contains coordinates for all 13 Uzbekistan districts', () {
      expect(WeatherService.districtCoordinates.containsKey('Toshkent'), isTrue);
      expect(WeatherService.districtCoordinates.containsKey('Samarqand'), isTrue);
      expect(WeatherService.districtCoordinates.containsKey('Buxoro'), isTrue);
      expect(WeatherService.districtCoordinates.containsKey('Andijon'), isTrue);
      expect(WeatherService.districtCoordinates.containsKey("Farg'ona"), isTrue);
      expect(WeatherService.districtCoordinates.containsKey('Namangan'), isTrue);
      expect(WeatherService.districtCoordinates.containsKey('Surxondaryo'), isTrue);
      expect(WeatherService.districtCoordinates.containsKey('Qashqadaryo'), isTrue);
      expect(WeatherService.districtCoordinates.containsKey('Jizzax'), isTrue);
      expect(WeatherService.districtCoordinates.containsKey('Sirdaryo'), isTrue);
      expect(WeatherService.districtCoordinates.containsKey('Xorazm'), isTrue);
      expect(WeatherService.districtCoordinates.containsKey('Navoiy'), isTrue);
      expect(WeatherService.districtCoordinates.containsKey("Qoraqalpog'iston"), isTrue);
    });

    test('7b. WeatherService.getWeatherForDistrict with forceRefresh: true clears weather_cache_Toshkent and fetches fresh data from HTTP client', () async {
      final staleWeather = WeatherData(
        district: 'Toshkent',
        temperature: 15.0,
        humidity: 60,
        windSpeed: 5.0,
        condition: 'clear',
        timestamp: DateTime.now(),
      );
      SharedPreferences.setMockInitialValues({
        'weather_cache_Toshkent': jsonEncode(staleWeather.toJson()),
      });

      int httpCallCount = 0;
      final mockClient = MockClient((request) async {
        httpCallCount++;
        return http.Response(
          jsonEncode({
            'current': {
              'temperature_2m': 29.5,
              'relative_humidity_2m': 42,
              'wind_speed_10m': 11.0,
              'weather_code': 1,
            },
          }),
          200,
        );
      });

      final service = WeatherService(client: mockClient);

      // Without forceRefresh, returns cached 15.0°C without hitting network
      final cachedResult = await service.getWeatherForDistrict('Toshkent', forceRefresh: false);
      expect(cachedResult.temperature, 15.0);
      expect(httpCallCount, 0);

      // With forceRefresh: true, clears cache and fetches 29.5°C from HTTP client
      final freshResult = await service.getWeatherForDistrict('Toshkent', forceRefresh: true);
      expect(httpCallCount, 1);
      expect(freshResult.temperature, 29.5);
      expect(freshResult.humidity, 42);
      expect(freshResult.condition, 'partly_cloudy');
    });
  });

  group('PoultryVisionAnalyzer Expert Diagnostics Tests', () {
    final analyzer = PoultryVisionAnalyzer();

    test('8. Recognizes bloody feces as coccidiosis and mandates vet referral', () async {
      final result = await analyzer.analyzeFlockImage(
        imagePath: '/tmp/dummy.jpg',
        userQuery: "Axlatida qon izlari ko'rindi",
        language: 'uz',
      );

      expect(result.conditionIdentified, contains('Koktsidioz'));
      expect(result.requiresImmediateVet, isTrue);
      expect(result.analysisText, contains('veterinariiga darhol xabar bering'));
    });

    test('9. Recognizes white diarrhea in Russian and alerts pullorum risk', () async {
      final result = await analyzer.analyzeFlockImage(
        imagePath: '/tmp/dummy.jpg',
        userQuery: "Белый понос у маленьких цыплят",
        language: 'ru',
      );

      expect(result.conditionIdentified, contains('Пуллороз'));
      expect(result.requiresImmediateVet, isTrue);
      expect(result.analysisText, contains('бактериологического посева'));
    });

    test('10. Recognizes open-beak panting as heat stress in English', () async {
      final result = await analyzer.analyzeFlockImage(
        imagePath: '/tmp/dummy.jpg',
        userQuery: "Birds are panting with beaks open and wings drooping",
        language: 'en',
      );

      expect(result.conditionIdentified, contains('Heat Stress'));
      expect(result.requiresImmediateVet, isFalse);
      expect(result.analysisText, contains('tunnel ventilation'));
    });

    test('11. Recognizes wet litter and ammonia risk', () async {
      final result = await analyzer.analyzeFlockImage(
        imagePath: '/tmp/dummy.jpg',
        userQuery: "To'shama ivib ketgan, suv ichish joylari nam",
        language: 'uz',
      );

      expect(result.conditionIdentified, contains('To\'shama namlanishi'));
      expect(result.analysisText, contains('ammiak gazi'));
    });
  });

  group('TtsService Tests', () {
    test('12. TtsService singleton instantiation and stop without error', () async {
      final tts = TtsService();
      expect(tts.isPlaying, isFalse);
      await tts.stop();
      expect(tts.isPlaying, isFalse);
    });
  });

  group('LocationService & Regional 6-Day Forecast Tests', () {
    test('13. LocationService.resolveNearestDistrict maps exact coordinates to nearest Uzbekistan region', () {
      expect(LocationService.resolveNearestDistrict(39.6542, 66.9597), 'Samarqand');
      expect(LocationService.resolveNearestDistrict(42.4619, 59.6166), "Qoraqalpog'iston");
      expect(LocationService.resolveNearestDistrict(37.2242, 67.2783), 'Surxondaryo');
      expect(LocationService.resolveNearestDistrict(40.3842, 71.7843), "Farg'ona");
    });

    test('14. LocationService.detectAndSaveLocation persists nearest district, GPS coords, and resolves prompt', () async {
      SharedPreferences.setMockInitialValues({});
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'latitude': 39.7747,
            'longitude': 64.4286,
          }),
          200,
        );
      });

      final service = LocationService(
        client: mockClient,
        permissionChecker: () async => true,
      );

      final result = await service.detectAndSaveLocation();
      expect(result.success, isTrue);
      expect(result.district, 'Buxoro');
      expect(result.latitude, closeTo(39.7747, 0.001));
      expect(result.longitude, closeTo(64.4286, 0.001));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('farmer_district'), 'Buxoro');
      expect(prefs.getBool('location_auto_detected'), isTrue);
      expect(prefs.getBool('location_prompt_resolved'), isTrue);
    });

    test('15. LocationService.saveManualDistrict overrides auto-detected coords and updates farmer_district', () async {
      SharedPreferences.setMockInitialValues({
        'farmer_district': 'Buxoro',
        'farmer_lat': 39.77,
        'farmer_lon': 64.42,
        'location_auto_detected': true,
      });

      await LocationService.saveManualDistrict('Namangan');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('farmer_district'), 'Namangan');
      expect(prefs.getBool('location_auto_detected'), isFalse);
      expect(prefs.getDouble('farmer_lat'), isNull);
      expect(prefs.getDouble('farmer_lon'), isNull);
      expect(prefs.getBool('location_prompt_resolved'), isTrue);
    });

    test('16. WeatherData.fallback provides distinct regional temperatures and 6-day forecast (D-2..D+3)', () {
      final surxondaryo = WeatherData.fallback('Surxondaryo');
      final qoraqalpogiston = WeatherData.fallback("Qoraqalpog'iston");

      expect(surxondaryo.temperature, greaterThan(qoraqalpogiston.temperature));
      expect(surxondaryo.dailyForecast.length, 6);
      expect(
        surxondaryo.dailyForecast.map((d) => d.dayOffset).toList(),
        [-2, -1, 0, 1, 2, 3],
      );
    });
  });
}
