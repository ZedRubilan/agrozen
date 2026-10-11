import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrozen/domain/broiler/broiler_grower_library.dart';
import 'package:agrozen/presentation/widgets/broiler_grower_toolkit_card.dart';
import 'package:agrozen/presentation/widgets/simple_chicken_tracker_card.dart';
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

      expect(reqNormal.totalDailyFeedKg, closeTo(37.0, 1.0));
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

    testWidgets('BroilerGrowerToolkitCard renders tabs and triggers enhanced prompt', (tester) async {
      String? capturedPrompt;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BroilerGrowerToolkitCard(
                batchDay: 14,
                initialCount: 500,
                currentCount: 490,
                language: 'en',
                onAskEnhancedPrompt: (p) => capturedPrompt = p,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Ross-308 Broiler Grower Hub'), findsOneWidget);
      expect(find.textContaining('510 g'), findsOneWidget);

      // Switch to FCR & Calc tab
      await tester.tap(find.text('FCR & Calc'));
      await tester.pumpAndSettle();
      expect(find.textContaining('EPEF'), findsWidgets);

      // Switch to Library tab and tap a guide
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Lighting & Stocking Density'));
      await tester.pumpAndSettle();

      expect(capturedPrompt, isNotNull);
      expect(capturedPrompt, contains('Day 14'));
    });

    testWidgets('SimpleChickenTrackerCard categorizes Healthy, Watchlist, and Lost Today in 1 tap', (tester) async {
      int isolated = 5;
      int mortalityAdded = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleChickenTrackerCard(
              batchDay: 14,
              initialCount: 500,
              currentCount: 495,
              isolatedCount: isolated,
              todayMortality: 2,
              todayFeedKg: 32.0,
              lastWeightG: 500.0,
              language: 'en',
              onUpdateIsolatedCount: (val) => isolated = val,
              onQuickAddMortality: () => mortalityAdded++,
              onOpenLogMortality: () {},
              onOpenLogFeed: () {},
              onOpenLogWeight: () {},
            ),
          ),
        ),
      );

      // Healthy = 495 - 5 = 490
      expect(find.text('490'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Tap '+' on Watchlist to isolate 1 more weak chick
      await tester.tap(find.text('+'));
      await tester.pump();
      expect(isolated, 6);

      // Tap '+1' on Lost Today
      await tester.tap(find.text('+1'));
      await tester.pump();
      expect(mortalityAdded, 1);
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
}
