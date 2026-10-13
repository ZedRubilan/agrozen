import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrozen/domain/broiler/broiler_grower_library.dart';
import 'package:agrozen/data/repositories/knowledge_repository.dart';
import 'package:agrozen/services/local_rag.dart';
import 'package:agrozen/services/poultry_vision_analyzer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BroilerGrowerLibrary & FarmerPromptEnhancer Tests', () {
    test('42-day Ross-308 matrix provides monotonic weights and valid phases', () {
      expect(BroilerGrowerLibrary.allDays.length, 42);

      final day1 = BroilerGrowerLibrary.specForDay(1);
      final day7 = BroilerGrowerLibrary.specForDay(7);
      final day21 = BroilerGrowerLibrary.specForDay(21);
      final day42 = BroilerGrowerLibrary.specForDay(42);

      expect(day1.phaseKey, 'pre_starter');
      expect(day7.phaseKey, 'starter');
      expect(day21.phaseKey, 'grower');
      expect(day42.phaseKey, 'finisher_2');

      expect(day7.targetWeightG, greaterThan(day1.targetWeightG));
      expect(day21.targetWeightG, greaterThan(day7.targetWeightG));
      expect(day42.targetWeightG, greaterThan(day21.targetWeightG));

      expect(day1.lightHours + day1.darkHours, 24);
      expect(day21.lightHours, 18);
      expect(day21.darkHours, 6);
    });

    test('calculateFlockRequirements scales feed, water, nipples, and barn area', () {
      final reqNormal = BroilerGrowerLibrary.calculateFlockRequirements(
        day: 14,
        birdCount: 500,
        outsideTempC: 24.0,
      );
      final reqHot = BroilerGrowerLibrary.calculateFlockRequirements(
        day: 14,
        birdCount: 500,
        outsideTempC: 34.0,
      );

      // Day 14: 54 g/bird (knowledge/norms.json) × 500 birds = 27 kg.
      expect(reqNormal.totalDailyFeedKg, closeTo(27.0, 0.01));
      expect(reqHot.totalDailyWaterLiters, greaterThan(reqNormal.totalDailyWaterLiters));
      expect(reqNormal.recommendedNipples, (500 / 11).ceil());
      expect(reqNormal.recommendedFeederPans, 10);
      expect(reqNormal.requiredBarnAreaHarvestSqM, closeTo(500 / 13.0, 0.5));
    });

    test('evaluateEfficiency computes FCR and EPEF score with grade', () {
      final elite = BroilerGrowerLibrary.evaluateEfficiency(
        batchDay: 35,
        initialCount: 500,
        currentCount: 492,
        actualAverageWeightG: 2450,
      );
      expect(elite.epefScore, greaterThan(300));
      expect(elite.grade, 'A+');
    });

    test('FarmerPromptEnhancer enriches short queries in uz, ru, and en', () {
      final uzEnhanced = FarmerPromptEnhancer.enhanceFarmerPrompt(
        rawInput: 'yem',
        lang: 'uz',
        batchDay: 14,
        birdCount: 500,
      );
      expect(uzEnhanced, contains('14-kunda'));
      expect(uzEnhanced, contains('500 bosh'));
      expect(uzEnhanced, contains('FCR'));

      final ruEnhanced = FarmerPromptEnhancer.enhanceFarmerPrompt(
        rawInput: 'свет и плотность',
        lang: 'ru',
        batchDay: 21,
        birdCount: 600,
      );
      expect(ruEnhanced, contains('21-й день'));
      expect(ruEnhanced, contains('600'));
      expect(ruEnhanced, contains('люкс'));

      final enEnhanced = FarmerPromptEnhancer.enhanceFarmerPrompt(
        rawInput: 'grow faster',
        lang: 'en',
        batchDay: 7,
        birdCount: 400,
      );
      expect(enEnhanced, contains('Day 7'));
      expect(enEnhanced, contains('185g'));
    });

    test('LocalRag retrieves new 09_lighting_density and 10_growth_fcr manuals', () async {
      final rag = LocalRag(KnowledgeRepository());

      final lightRes = await rag.answer(
        question: 'What is the lighting schedule and stocking density per m2?',
        language: 'en',
      );
      expect(lightRes, isNotNull);
      expect(lightRes!.answer.toLowerCase(), contains('lux'));

      final fcrRes = await rag.answer(
        question: 'Broyler FCR yem konversiyasi va EPEF nima?',
        language: 'uz',
      );
      expect(fcrRes, isNotNull);
      expect(fcrRes!.answer, contains('FCR'));
    });

    test('PoultryVisionAnalyzer detects PNG/JPEG MIME types and inspects image bytes', () async {
      final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      expect(PoultryVisionAnalyzer.detectMimeType('photo.jpg', pngBytes), 'image/png');
      expect(PoultryVisionAnalyzer.detectMimeType('chick.webp'), 'image/webp');
      expect(PoultryVisionAnalyzer.detectMimeType('chick.jpg'), 'image/jpeg');

      final sampleBytes = Uint8List.fromList(List.filled(2048, 160));
      final res = await PoultryVisionAnalyzer().analyzeFlockImage(
        imagePath: '',
        userQuery: 'Is the chicken in the photo fine and healthy?',
        language: 'en',
        imageBytesOverride: sampleBytes,
      );
      expect(res.analysisText, contains('STATUS VERDICT'));
      expect(res.analysisText, contains('Fine & Healthy Chick'));
    });
  });

  group('FCR plausibility is relative to the day target', () {
    test('an on-target early flock is graded, not rejected', () {
      // Day 7 target FCR is 0.75 — below the old fixed 0.9 cutoff.
      final day7 = BroilerGrowerLibrary.specForDay(7).targetFcr;
      expect(day7, lessThan(0.9));
      expect(BroilerGrowerLibrary.isPlausibleFcr(day: 7, fcr: day7), isTrue);
      expect(BroilerGrowerLibrary.isPlausibleFcr(day: 7, fcr: 0.6), isTrue);
    });

    test('far better than target means incomplete inputs', () {
      // Day 14 target 0.86 → floor 0.60.
      expect(BroilerGrowerLibrary.isPlausibleFcr(day: 14, fcr: 0.25), isFalse);
      expect(BroilerGrowerLibrary.isPlausibleFcr(day: 7, fcr: 0.4), isFalse);
      // Day 42 target 1.43 → floor 1.0.
      expect(BroilerGrowerLibrary.isPlausibleFcr(day: 42, fcr: 0.9), isFalse);
      expect(BroilerGrowerLibrary.isPlausibleFcr(day: 42, fcr: 1.5), isTrue);
    });
  });
}
