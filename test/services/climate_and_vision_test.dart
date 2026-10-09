import 'package:flutter_test/flutter_test.dart';
import 'package:agrozen/data/models/weather_data.dart';
import 'package:agrozen/domain/climate/climate_advisor.dart';
import 'package:agrozen/services/poultry_vision_analyzer.dart';
import 'package:agrozen/services/tts_service.dart';
import 'package:agrozen/services/weather_service.dart';

void main() {
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
}
