import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrozen/config/theme.dart';
import 'package:agrozen/presentation/screens/splash_screen.dart';
import 'package:agrozen/presentation/screens/onboarding/language_screen.dart';
import 'package:agrozen/presentation/screens/onboarding/region_screen.dart';
import 'package:agrozen/presentation/screens/onboarding/batch_setup_screen.dart';
import 'package:agrozen/presentation/screens/onboarding/disclaimer_screen.dart';
import 'package:agrozen/presentation/screens/home_screen.dart';
import 'package:agrozen/presentation/screens/daily_plan_screen.dart';
import 'package:agrozen/presentation/screens/diary/diary_screen.dart';
import 'package:agrozen/presentation/screens/diary/log_mortality_screen.dart';
import 'package:agrozen/presentation/screens/diary/log_feed_screen.dart';
import 'package:agrozen/presentation/screens/diary/log_weight_screen.dart';
import 'package:agrozen/presentation/screens/ask/ask_screen.dart';
import 'package:agrozen/presentation/screens/course/course_list_screen.dart';
import 'package:agrozen/presentation/screens/course/lesson_screen.dart';
import 'package:agrozen/presentation/screens/course/quiz_screen.dart';
import 'package:agrozen/presentation/screens/course/certificate_screen.dart';
import 'package:agrozen/presentation/screens/settings_screen.dart';
import 'package:agrozen/presentation/screens/tools_screen.dart';
import 'package:agrozen/services/daily_counters.dart';
import 'package:agrozen/services/farm_store.dart';
import 'package:agrozen/presentation/widgets/alert_card.dart';

Widget createTestApp(Widget child) {
  Widget mock(String label) => Scaffold(body: Text(label));
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(
        path: '/onboarding/language',
        builder: (_, __) => mock('LanguageMock'),
      ),
      GoRoute(
        path: '/onboarding/region',
        builder: (_, __) => mock('RegionMock'),
      ),
      GoRoute(path: '/onboarding/batch', builder: (_, __) => mock('BatchMock')),
      GoRoute(
        path: '/onboarding/disclaimer',
        builder: (_, __) => mock('DisclaimerMock'),
      ),
      GoRoute(path: '/home', builder: (_, __) => mock('HomeMock')),
      GoRoute(path: '/daily-plan', builder: (_, __) => mock('DailyPlanMock')),
      GoRoute(path: '/tools', builder: (_, __) => mock('ToolsMock')),
      GoRoute(
        path: '/diary/mortality',
        builder: (_, __) => mock('MortalityMock'),
      ),
      GoRoute(path: '/diary/feed', builder: (_, __) => mock('FeedMock')),
      GoRoute(path: '/diary/weight', builder: (_, __) => mock('WeightMock')),
      GoRoute(
        path: '/course/:id',
        builder: (_, s) => mock('LessonMock ${s.pathParameters['id']}'),
      ),
      GoRoute(path: '/course/:id/quiz', builder: (_, __) => mock('QuizMock')),
      GoRoute(path: '/certificate', builder: (_, __) => mock('CertMock')),
      GoRoute(path: '/settings', builder: (_, __) => mock('SettingsMock')),
    ],
  );
  return MaterialApp.router(
    theme: AppTheme.lightTheme,
    routerConfig: router,
    // Tests run with "reduce motion": the weather scene loops forever and
    // would never let pumpAndSettle settle; this also covers the still path.
    builder: _reduceMotion,
  );
}

Widget _reduceMotion(BuildContext context, Widget? child) => MediaQuery(
  data: MediaQuery.of(context).copyWith(disableAnimations: true),
  child: child!,
);

/// Scrolls [finder] into view before tapping (the test screen is 800×600).
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

String _daysAgo(int days) =>
    DateTime.now().subtract(Duration(days: days)).toIso8601String();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Logical Flow Verification', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      '1. Fresh launch: splash routes straight to onboarding without a spinner',
      (tester) async {
        SharedPreferences.setMockInitialValues({'is_onboarded': false});
        await tester.pumpWidget(createTestApp(const SplashScreen()));
        await tester.pump();

        expect(find.text('AgroZen'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await tester.pumpAndSettle();
        expect(find.text('LanguageMock'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Language step shows flags and step counter and saves the choice',
      (tester) async {
        await tester.pumpWidget(createTestApp(const LanguageScreen()));
        await tester.pumpAndSettle();

        expect(
          find.text("Tilni tanlang\nВыберите язык\nSelect Language"),
          findsOneWidget,
        );
        expect(find.text('1 / 4'), findsOneWidget);
        expect(find.text("O'zbekcha"), findsOneWidget);
        expect(find.text('Русский'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);

        await tester.tap(find.text('Русский'));
        await tester.pumpAndSettle();
        // The button follows the selected language immediately.
        await tester.tap(find.text('Далее'));
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('app_language'), 'ru');
        expect(find.text('RegionMock'), findsOneWidget);
      },
    );

    testWidgets('3. Region step selects a district', (tester) async {
      SharedPreferences.setMockInitialValues({'app_language': 'uz'});
      await tester.pumpWidget(createTestApp(const RegionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Fermangiz qayerda?'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Samar');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Samarqand').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keyingisi'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('farmer_district'), 'Samarqand');
      expect(find.text('BatchMock'), findsOneWidget);
    });

    testWidgets('4. Batch step validates input and stores the flock', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'app_language': 'uz'});
      await tester.pumpWidget(createTestApp(const BatchSetupScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Yangi broyler partiyasi'), findsOneWidget);

      // Empty name is rejected.
      await tester.tap(find.text('Keyingisi'));
      await tester.pumpAndSettle();
      expect(find.text('Ismni kiriting'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ismingiz'),
        'Alisher Fermer',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, "Jo'jalar soni"),
        '1000',
      );
      await tester.tap(find.text('Keyingisi'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('farmer_name'), 'Alisher Fermer');
      expect(prefs.getInt('initial_count'), 1000);
      expect(prefs.getInt('current_count'), 1000);
      expect(prefs.getString('arrival_date'), isNotNull);
      expect(find.text('DisclaimerMock'), findsOneWidget);
    });

    testWidgets('5. Disclaimer step completes onboarding', (tester) async {
      SharedPreferences.setMockInitialValues({'app_language': 'uz'});
      await tester.pumpWidget(createTestApp(const DisclaimerScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Muhim ogohlantirish'), findsOneWidget);
      await tester.tap(find.text('Tushundim va roziman'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('disclaimer_accepted'), true);
      expect(prefs.getBool('is_onboarded'), true);
      expect(find.text('HomeMock'), findsOneWidget);
    });

    testWidgets('6. Today tab shows day, flock and norms.json targets', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'is_onboarded': true,
        'app_language': 'uz',
        'farmer_name': 'Zafar aka',
        'farmer_district': 'Buxoro',
        'location_prompt_resolved': true,
        'initial_count': 500,
        'current_count': 498,
        'arrival_date': _daysAgo(6), // Day 7
      });

      await tester.pumpWidget(createTestApp(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Assalomu alaykum, Zafar aka!'), findsOneWidget);
      expect(find.text('7-kun (42 kundan)'), findsOneWidget);
      expect(find.textContaining('498 ta tirik'), findsOneWidget);
      // Day 7 in knowledge/norms.json: 29.5°C, 27 g feed/bird -> 498 birds ≈ 13.4 kg.
      expect(find.text('29.5°C'), findsOneWidget);
      expect(find.text('13.4 kg'), findsOneWidget);
      // Four labelled tabs.
      expect(find.byType(NavigationDestination), findsNWidgets(4));
    });

    testWidgets('6b. Today tab task checklist ticks are saved per batch day', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'is_onboarded': true,
        'app_language': 'en',
        'location_prompt_resolved': true,
        'arrival_date': _daysAgo(0), // Day 1
      });

      await tester.pumpWidget(createTestApp(const HomeScreen()));
      await tester.pumpAndSettle();

      await tapVisible(
        tester,
        find.textContaining('Provide 23-24 hours of bright lighting'),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('plan_tasks_done_1'), ['1']);
    });

    testWidgets('7. 42-day plan shows today and lets the farmer browse days', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'uz',
        'arrival_date': _daysAgo(0), // Day 1
      });

      await tester.pumpWidget(createTestApp(const DailyPlanScreen()));
      await tester.pumpAndSettle();

      expect(find.text('42 kunlik reja'), findsOneWidget);
      expect(find.text('1-kun · Start'), findsOneWidget);
      expect(find.text('Bugun'), findsOneWidget);
      expect(find.text('32.5°C'), findsOneWidget);

      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(find.text('2-kun · Start'), findsOneWidget);
      expect(find.text('32°C'), findsOneWidget);
    });

    testWidgets('8. Diary shows today, batch totals and the log actions', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'counters_date': DailyCounters.todayStamp(),
        'app_language': 'uz',
        'initial_count': 600,
        'current_count': 590,
        'today_mortality': 2,
        'today_feed': 45.0,
        'last_weight': 480.0,
      });

      await tester.pumpWidget(createTestApp(const DiaryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Partiya kundaligi'), findsOneWidget);
      expect(find.text('Nobodlik yozish'), findsOneWidget);
      expect(find.text('Yem sarfini yozish'), findsOneWidget);
      expect(find.text('Nazorat vaznini yozish'), findsOneWidget);
      expect(find.text('Bugun: 2 bosh'), findsOneWidget);
      await tapVisible(tester, find.text("Partiya bo'yicha"));
      expect(find.text('590'), findsOneWidget);
      expect(find.text('10'), findsOneWidget); // total lost
    });

    testWidgets('8b. Diary keeps a day-by-day history of what was logged', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'uz',
        'initial_count': 500,
        'current_count': 500,
        'arrival_date': _daysAgo(4), // Day 5
      });
      await FarmStore.logFeed(12.5);
      await FarmStore.logDeaths(3);

      await tester.pumpWidget(createTestApp(const DiaryScreen()));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text("Kunlar bo'yicha"));
      final day = find.text('5-kun');
      await tester.ensureVisible(day);
      expect(day, findsOneWidget);
      expect(find.text('12.5 kg'), findsWidgets);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('current_count'), 497);
      expect(FarmStore.readHistory(prefs).single.deaths, 3);
    });

    testWidgets('9. Recording deaths above 1% raises the vet alert', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'counters_date': DailyCounters.todayStamp(),
        'app_language': 'uz',
        'farmer_district': 'Namangan',
        'initial_count': 500,
        'current_count': 500,
        'today_mortality': 0,
      });

      await tester.pumpWidget(createTestApp(const LogMortalityScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '15'); // 3.0% of 500
      await tester.tap(find.text('Qaydni saqlash'));
      await tester.pumpAndSettle();

      expect(find.text('Diqqat: Yuqori nobodlik!'), findsOneWidget);
      expect(find.textContaining('3.0% > 1.0%'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('today_mortality'), 15);
      expect(prefs.getInt('current_count'), 485);
    });

    testWidgets('9b. Deaths cannot exceed the live flock', (tester) async {
      SharedPreferences.setMockInitialValues({
        'counters_date': DailyCounters.todayStamp(),
        'app_language': 'uz',
        'current_count': 10,
      });

      await tester.pumpWidget(createTestApp(const LogMortalityScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '11');
      await tester.tap(find.text('Qaydni saqlash'));
      await tester.pumpAndSettle();

      expect(
        find.text("Tirik jo'jalar sonidan ko'p bo'la olmaydi"),
        findsOneWidget,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('current_count'), 10);
    });

    testWidgets('10. Recording feed adds to today and quick-add buttons work', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'counters_date': DailyCounters.todayStamp(),
        'app_language': 'uz',
        'today_feed': 10.0,
      });

      await tester.pumpWidget(createTestApp(const LogFeedScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('+25'));
      await tester.tap(find.text('+5'));
      await tester.pump();
      expect(find.widgetWithText(TextFormField, '30'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '25.5');
      await tester.tap(find.text('Qaydni saqlash'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('today_feed'), 35.5);
    });

    testWidgets('11. Recording a low sample weight raises the warning', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'uz',
        'farmer_district': 'Toshkent',
        'arrival_date': _daysAgo(13), // Day 14, target 510 g
      });

      await tester.pumpWidget(createTestApp(const LogWeightScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '380');
      await tester.tap(find.text('Qaydni saqlash'));
      await tester.pumpAndSettle();

      expect(find.text('Diqqat: Vazn ortda qolmoqda!'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('last_weight'), 380.0);
      expect(prefs.getInt('last_weight_day'), 14);
    });

    testWidgets(
      '12. Assistant enforces the medicine rule and decrements the quota',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'app_language': 'uz',
          'remaining_questions': 30,
        });

        await tester.pumpWidget(createTestApp(const AskScreen()));
        await tester.pumpAndSettle();

        expect(find.textContaining('Bugun qoldi: 30/30'), findsOneWidget);

        final input = find.byType(TextField);
        await tester.enterText(input, "Jo'jalarga qanday harorat kerak?");
        await tester.pump();
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        expect(find.textContaining('Bugun qoldi: 29/30'), findsOneWidget);
        expect(find.textContaining('Harorat va namlik'), findsOneWidget);

        await tester.enterText(
          input,
          'Qanday dori va antibiotik berish kerak?',
        );
        await tester.pump();
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        expect(
          find.textContaining(
            'AgroZen mustaqil ravishda dori yoki antibiotik belgilamaydi',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('darhol tumaningiz veterinariga murojaat qiling'),
          findsOneWidget,
        );
      },
    );

    testWidgets('12b. Assistant shows the mic when the input is empty', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'app_language': 'uz'});

      await tester.pumpWidget(
        createTestApp(const AskScreen(startInFieldMode: true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('AgroZen yordamchisi'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsNothing);
      expect(find.text('Tez savollar'), findsOneWidget);
    });

    testWidgets('12c. Assistant answers "hello" warmly with the flock status', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'uz',
        'farmer_name': 'Rustam aka',
        'current_count': 480,
        'remaining_questions': 30,
      });

      await tester.pumpWidget(
        createTestApp(const AskScreen(startInFieldMode: true)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('hello'), findsOneWidget);
      expect(find.textContaining('Hello, Rustam aka!'), findsOneWidget);
      expect(find.textContaining('480 birds'), findsOneWidget);
      expect(
        find.textContaining('I could not find a specific answer'),
        findsNothing,
      );
    });

    testWidgets('13. Course: list, lesson and quiz award completion', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'uz',
        'completed_lessons': <String>[],
      });

      await tester.pumpWidget(createTestApp(const CourseListScreen()));
      await tester.pumpAndSettle();
      expect(find.text("O'rganish"), findsOneWidget);
      expect(find.text('0 / 5 dars tugatildi'), findsOneWidget);
      expect(
        find.text("Jo'jalar kelishidan oldin xonani tayyorlash"),
        findsOneWidget,
      );
      await tester.tap(find.text('Kursni boshlash'));
      await tester.pumpAndSettle();
      expect(find.text('LessonMock 1'), findsOneWidget);

      await tester.pumpWidget(createTestApp(const LessonScreen(lessonId: 1)));
      await tester.pumpAndSettle();
      expect(
        find.text("Jo'jalar kelishidan oldin xonani tayyorlash"),
        findsOneWidget,
      );
      expect(find.text('Testni boshlash'), findsOneWidget);

      await tester.pumpWidget(createTestApp(const QuizScreen(lessonId: 1)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20-22°C'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Tekshirish'));
      expect(find.text("Noto'g'ri. Yana urinib ko'ring."), findsOneWidget);

      await tapVisible(tester, find.text('Qayta urinish'));
      await tester.tap(find.text('33-34°C'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Tekshirish'));
      expect(find.text("To'g'ri! Dars tugatildi."), findsOneWidget);
      expect(find.text('Keyingi dars'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('completed_lessons'), contains('1'));
    });

    testWidgets('14. Certificate is locked until all 5 lessons are passed', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'uz',
        'farmer_name': 'Rustamjon Qodirov',
        'farmer_district': 'Andijon',
        'completed_lessons': <String>['1', '2'],
      });
      await tester.pumpWidget(createTestApp(const CertificateScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Avval 5 ta darsni tugating'), findsOneWidget);
      expect(find.text('Rustamjon Qodirov'), findsNothing);

      SharedPreferences.setMockInitialValues({
        'app_language': 'uz',
        'farmer_name': 'Rustamjon Qodirov',
        'farmer_district': 'Andijon',
        'completed_lessons': <String>['1', '2', '3', '4', '5'],
      });
      await tester.pumpWidget(
        createTestApp(const CertificateScreen(key: ValueKey('done'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rustamjon Qodirov'), findsOneWidget);
      expect(find.text('SERTIFIKAT'), findsOneWidget);
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    });

    testWidgets('15. Settings shows the farm and switches language', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'uz',
        'farmer_name': 'Botir aka',
        'farmer_district': "Farg'ona",
        'initial_count': 800,
        'current_count': 800,
      });

      await tester.pumpWidget(createTestApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Botir aka'), findsOneWidget);
      expect(find.textContaining("Farg'ona"), findsWidgets);
      expect(find.text("800 ta jo'ja"), findsOneWidget);

      await tester.tap(find.text('Русский'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language'), 'ru');
      expect(find.text('Настройки'), findsOneWidget);
    });

    testWidgets('16. New batch after reset (already onboarded) returns home', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'is_onboarded': true,
        'app_language': 'uz',
      });

      await tester.pumpWidget(createTestApp(const BatchSetupScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ismingiz'),
        'Otabek Fermer',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, "Jo'jalar soni"),
        '750',
      );
      await tester.tap(find.text('Saqlash'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('farmer_name'), 'Otabek Fermer');
      expect(prefs.getInt('initial_count'), 750);
      expect(prefs.getInt('current_count'), 750);
      expect(find.text('HomeMock'), findsOneWidget);
    });

    testWidgets(
      '16b. Editing the batch size keeps the deaths already recorded',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_onboarded': true,
          'app_language': 'uz',
          'farmer_name': 'Otabek',
          'initial_count': 500,
          'current_count': 490,
          'arrival_date': _daysAgo(9),
        });

        await tester.pumpWidget(createTestApp(const BatchSetupScreen()));
        await tester.pumpAndSettle();
        expect(find.text("Partiya ma'lumotlari"), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextFormField, "Jo'jalar soni"),
          '600',
        );
        await tester.tap(find.text('Saqlash'));
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('initial_count'), 600);
        expect(prefs.getInt('current_count'), 590);
      },
    );

    testWidgets('17. Diary alerts use start-of-day mortality and low weight', (
      tester,
    ) async {
      final base = {
        'counters_date': DailyCounters.todayStamp(),
        'app_language': 'uz',
        'initial_count': 100,
        'current_count': 99,
        'today_mortality': 1,
        'arrival_date': _daysAgo(13), // Day 14
      };

      // 1 of 100 start-of-day birds = 1.0% — not above the 1% threshold.
      SharedPreferences.setMockInitialValues({...base, 'last_weight': 0.0});
      await tester.pumpWidget(createTestApp(const DiaryScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(AlertCard), findsNothing);

      // 350 g on day 14 (target 510 g) is more than 15% under.
      SharedPreferences.setMockInitialValues({...base, 'last_weight': 350.0});
      await tester.pumpWidget(
        createTestApp(const DiaryScreen(key: ValueKey('low'))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertCard), findsOneWidget);
      expect(find.textContaining('350g'), findsOneWidget);
    });

    testWidgets(
      '17b. An old weighing is judged against the target of the day it was weighed',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'app_language': 'uz',
          'initial_count': 100,
          'current_count': 100,
          'arrival_date': _daysAgo(13), // Day 14 (target 510 g)
          'last_weight': 150.0, // weighed on day 6 (target 145 g)
          'last_weight_day': 6,
        });

        await tester.pumpWidget(createTestApp(const DiaryScreen()));
        await tester.pumpAndSettle();
        expect(find.byType(AlertCard), findsNothing);
      },
    );

    testWidgets('18. English: Today tab and quiz have no Uzbek leakage', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'is_onboarded': true,
        'app_language': 'en',
        'farmer_name': 'John Farmer',
        'farmer_district': 'Samarqand',
        'location_prompt_resolved': true,
        'initial_count': 500,
        'current_count': 498,
        'arrival_date': _daysAgo(6),
      });

      await tester.pumpWidget(createTestApp(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Hello, John Farmer!'), findsOneWidget);
      expect(find.text("Today's targets"), findsOneWidget);
      expect(find.text('House temperature'), findsOneWidget);
      expect(find.text('Day 7 of 42'), findsOneWidget);
      expect(find.text('Assalomu alaykum, John Farmer!'), findsNothing);

      await tester.pumpWidget(createTestApp(const QuizScreen(lessonId: 1)));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'To what temperature should the barn be preheated 24 hours before chick arrival?',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('33-34°C'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Check answer'));

      expect(find.text('Correct! Lesson complete.'), findsOneWidget);
      expect(
        find.textContaining(
          'Day-old chicks cannot regulate their own body temperature',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      '19. Calculators compute FCR from the diary and a profit estimate',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'app_language': 'en',
          'initial_count': 1000,
          'current_count': 1000,
          'arrival_date': _daysAgo(34), // Day 35
          'last_weight': 2480.0,
        });

        await tester.pumpWidget(createTestApp(const ToolsScreen()));
        await tester.pumpAndSettle();

        expect(
          find.text('Enter weight and feed to see the result.'),
          findsOneWidget,
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Total feed given'),
          '3720',
        );
        await tester.pumpAndSettle();

        // 3720 kg / (1000 × 2.48 kg) = 1.50
        expect(find.text('1.50'), findsOneWidget);
        expect(find.text('Net profit'), findsOneWidget);
      },
    );

    testWidgets(
      '19b. Calculators refuse to grade an impossible FCR from partial feed data',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'app_language': 'en',
          'initial_count': 1000,
          'current_count': 986,
          'arrival_date': _daysAgo(13), // Day 14
          'last_weight': 470.0,
        });
        await FarmStore.logFeed(30); // only one day of feed in the diary

        await tester.pumpWidget(createTestApp(const ToolsScreen()));
        await tester.pumpAndSettle();

        // A partial diary total is not pre-filled as the batch total.
        expect(find.widgetWithText(TextField, '30'), findsNothing);
        expect(find.textContaining('13 days are missing'), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextField, 'Total feed given'),
          '116.5',
        );
        await tester.pumpAndSettle();
        expect(find.textContaining("too low to be real"), findsOneWidget);
        expect(find.text('EPEF'), findsNothing);
      },
    );
  });
}
