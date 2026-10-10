import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:agrozen/services/daily_counters.dart';
import 'package:agrozen/presentation/widgets/alert_card.dart';

Widget createTestApp(Widget child) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(path: '/onboarding/language', builder: (context, state) => const Scaffold(body: Text('LanguageMock'))),
      GoRoute(path: '/onboarding/region', builder: (context, state) => const Scaffold(body: Text('RegionMock'))),
      GoRoute(path: '/onboarding/batch', builder: (context, state) => const Scaffold(body: Text('BatchMock'))),
      GoRoute(path: '/onboarding/disclaimer', builder: (context, state) => const Scaffold(body: Text('DisclaimerMock'))),
      GoRoute(path: '/home', builder: (context, state) => const Scaffold(body: Text('HomeMock'))),
      GoRoute(path: '/daily-plan', builder: (context, state) => const Scaffold(body: Text('DailyPlanMock'))),
      GoRoute(path: '/diary', builder: (context, state) => const Scaffold(body: Text('DiaryMock'))),
      GoRoute(path: '/diary/mortality', builder: (context, state) => const Scaffold(body: Text('MortalityMock'))),
      GoRoute(path: '/diary/feed', builder: (context, state) => const Scaffold(body: Text('FeedMock'))),
      GoRoute(path: '/diary/weight', builder: (context, state) => const Scaffold(body: Text('WeightMock'))),
      GoRoute(path: '/ask', builder: (context, state) => const Scaffold(body: Text('AskMock'))),
      GoRoute(path: '/course', builder: (context, state) => const Scaffold(body: Text('CourseMock'))),
      GoRoute(path: '/certificate', builder: (context, state) => const Scaffold(body: Text('CertMock'))),
      GoRoute(path: '/settings', builder: (context, state) => const Scaffold(body: Text('SettingsMock'))),
    ],
  );
  return MaterialApp.router(
    routerConfig: router,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Logical Flow Verification', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('1. Fresh Launch: Splash Screen routes to Onboarding when not onboarded', (tester) async {
      SharedPreferences.setMockInitialValues({'is_onboarded': false});

      await tester.pumpWidget(createTestApp(const SplashScreen()));

      expect(find.text('AgroZen'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('LanguageMock'), findsOneWidget);
    });

    testWidgets('2. Language Selection Screen stores choice in SharedPreferences', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(createTestApp(const LanguageScreen()));

      expect(find.text("Tilni tanlang\nВыберите язык\nSelect Language"), findsOneWidget);
      expect(find.text("O'zbekcha"), findsOneWidget);
      expect(find.text("Русский"), findsOneWidget);
      expect(find.text("English"), findsOneWidget);

      // Select Russian
      await tester.tap(find.text("Русский"));
      await tester.pumpAndSettle();

      // Tap Proceed
      await tester.tap(find.text("Davom etish / Далее / Continue"));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language'), 'ru');
      expect(find.text('RegionMock'), findsOneWidget);
    });

    testWidgets('3. Region Selection Screen filters and selects district', (tester) async {
      SharedPreferences.setMockInitialValues({'app_language': 'uz'});

      await tester.pumpWidget(createTestApp(const RegionScreen()));

      expect(find.text('Viloyatni tanlang'), findsOneWidget);
      expect(find.text('Samarqand'), findsOneWidget);

      // Select Samarqand
      await tester.tap(find.text('Samarqand'));
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Keyingisi'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('farmer_district'), 'Samarqand');
      expect(find.text('BatchMock'), findsOneWidget);
    });

    testWidgets('4. Batch Setup Screen validates input and stores flock parameters', (tester) async {
      SharedPreferences.setMockInitialValues({'app_language': 'uz'});

      await tester.pumpWidget(createTestApp(const BatchSetupScreen()));

      expect(find.text('Yangi broyler partiyasi'), findsOneWidget);

      final nameField = find.widgetWithText(TextFormField, 'Ismingiz / Ferma nomi');
      final countField = find.widgetWithText(TextFormField, "Jo'jalar soni (bosh)");

      await tester.enterText(nameField, 'Alisher Fermer');
      await tester.enterText(countField, '1000');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Keyingisi'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('farmer_name'), 'Alisher Fermer');
      expect(prefs.getInt('initial_count'), 1000);
      expect(prefs.getInt('current_count'), 1000);
      expect(prefs.getString('arrival_date'), isNotNull);
      expect(find.text('DisclaimerMock'), findsOneWidget);
    });

    testWidgets('5. Legal Disclaimer Screen completes onboarding', (tester) async {
      SharedPreferences.setMockInitialValues({'app_language': 'uz'});

      await tester.pumpWidget(createTestApp(const DisclaimerScreen()));

      expect(find.text('Muhim ogohlantirish'), findsOneWidget);
      expect(find.text('Tushundim va roziman'), findsOneWidget);

      // Accept
      await tester.tap(find.text('Tushundim va roziman'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('disclaimer_accepted'), true);
      expect(prefs.getBool('is_onboarded'), true);
      expect(find.text('HomeMock'), findsOneWidget);
    });

    testWidgets('6. Dashboard Screen renders current day progress and metrics', (tester) async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        'is_onboarded': true,
        'app_language': 'uz',
        'farmer_name': 'Zafar aka',
        'farmer_district': 'Buxoro',
        'initial_count': 500,
        'current_count': 498,
        'arrival_date': now.subtract(const Duration(days: 6)).toIso8601String(), // Day 7
      });

      await tester.pumpWidget(createTestApp(const HomeScreen()));
      await tester.pumpAndSettle();

      // Check greetings and day progress
      expect(find.text('Assalomu alaykum, Zafar aka!'), findsOneWidget);
      expect(find.text('7-kun (42 kundan)'), findsOneWidget);
      expect(find.text('498'), findsOneWidget);
      expect(find.text('30°C'), findsWidgets); // Day 7 temp norm is 29.5 -> 30°C from norms.json
    });

    testWidgets('7. Daily Plan Screen navigates timeline and displays growth stage guidance', (tester) async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'uz',
        'arrival_date': DateTime.now().toIso8601String(), // Day 1
      });

      await tester.pumpWidget(createTestApp(const DailyPlanScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Kunlik reja (1–42)'), findsOneWidget);
      expect(find.text('Bu sizning bugungi partiya kuningiz!'), findsOneWidget);
      expect(find.text("Bosqich bo'yicha tavsiyalar"), findsOneWidget);
    });

    testWidgets('8. Flock Diary Screen displays flock metrics and action entries', (tester) async {
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
      expect(find.text('590'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('480 г'), findsNWidgets(2));
      expect(find.text("Nobodlik yozish"), findsOneWidget);
      expect(find.text("Yem sarfini yozish"), findsOneWidget);
      expect(find.text("Nazorat vaznini yozish"), findsOneWidget);
    });

    testWidgets('9. Log Mortality Screen triggers veterinary alert when exceeding 1% threshold', (tester) async {
      SharedPreferences.setMockInitialValues({
        'counters_date': DailyCounters.todayStamp(),
        'app_language': 'uz',
        'farmer_district': 'Namangan',
        'current_count': 500,
        'today_mortality': 0,
      });

      await tester.pumpWidget(createTestApp(const LogMortalityScreen()));
      await tester.pumpAndSettle();

      // Enter 15 deaths (3.0% of 500 > 1.0% limit)
      final input = find.byType(TextFormField);
      await tester.enterText(input, '15');
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Qaydni saqlash'));
      await tester.pumpAndSettle();

      // Alert dialog should appear with vet alert
      expect(find.text("Diqqat: Yuqori nobodlik!"), findsOneWidget);
      expect(find.textContaining('3.0% > 1.0%'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('today_mortality'), 15);
      expect(prefs.getInt('current_count'), 485);
    });

    testWidgets('10. Log Feed Screen saves feed consumption', (tester) async {
      SharedPreferences.setMockInitialValues({
        'counters_date': DailyCounters.todayStamp(),
        'app_language': 'uz',
        'today_feed': 10.0,
      });

      await tester.pumpWidget(createTestApp(const LogFeedScreen()));
      await tester.pumpAndSettle();

      final input = find.byType(TextFormField);
      await tester.enterText(input, '25.5');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Qaydni saqlash'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('today_feed'), 35.5);
    });

    testWidgets('11. Log Weight Screen triggers underweight warning on severe deficit', (tester) async {
      final arrivalDate = DateTime.now().subtract(const Duration(days: 13)); // Day 14 (target ~500g)
      SharedPreferences.setMockInitialValues({
        'app_language': 'uz',
        'farmer_district': 'Toshkent',
        'arrival_date': arrivalDate.toIso8601String(),
      });

      await tester.pumpWidget(createTestApp(const LogWeightScreen()));
      await tester.pumpAndSettle();

      // Enter 380g (norm is 500g, 380g is 24% below norm > 15% threshold)
      final input = find.byType(TextFormField);
      await tester.enterText(input, '380');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Qaydni saqlash'));
      await tester.pumpAndSettle();

      // Alert dialog should pop up
      expect(find.text("Diqqat: Vazn ortda qolmoqda!"), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('last_weight'), 380.0);
    });

    testWidgets('12. Ask AI Chat Screen enforces safety rules and decrements daily quota', (tester) async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'uz',
        'remaining_questions': 30,
      });

      await tester.pumpWidget(createTestApp(const AskScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Bugun qoldi: 30/30'), findsOneWidget);

      // Ask question about temperature
      final input = find.byType(TextField);
      await tester.enterText(input, "Jo'jalarga qanday harorat kerak?");
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Quota should decrement
      expect(find.textContaining('Bugun qoldi: 29/30'), findsOneWidget);
      // Answer should cite temperature topic
      expect(find.textContaining('Harorat va namlik'), findsOneWidget);

      // Ask dangerous medical query (drugs/antibiotics)
      await tester.enterText(input, "Qanday dori va antibiotik berish kerak?");
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Verifying non-prescriptive safety rule
      expect(find.textContaining('AgroZen mustaqil ravishda dori yoki antibiotik belgilamaydi'), findsOneWidget);
      expect(find.textContaining('darhol tumaningiz veterinariga murojaat qiling'), findsOneWidget);
    });

    testWidgets('12b. AskScreen startInFieldMode builds safely without empty list exceptions', (tester) async {
      SharedPreferences.setMockInitialValues({'app_language': 'uz'});

      await tester.pumpWidget(createTestApp(const AskScreen(startInFieldMode: true)));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('AgroZen AI Maslahatchi'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('13. Pre-Credit Course & Quiz Flow awards completion', (tester) async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'uz',
        'completed_lessons': <String>[],
      });

      // 1. Course list
      await tester.pumpWidget(createTestApp(const CourseListScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Kreditdan oldingi kurs'), findsOneWidget);
      expect(find.text('Tugallandi: 0 / 5'), findsOneWidget);

      // 2. Lesson screen
      await tester.pumpWidget(createTestApp(const LessonScreen(lessonId: 1)));
      await tester.pumpAndSettle();
      expect(find.text("Jo'jalar kelishidan oldin xonani tayyorlash"), findsOneWidget);
      expect(find.text('Dars testini topshirish'), findsOneWidget);

      // 3. Quiz screen (correct answer for Lesson 1 is 33-34°C, index 2)
      await tester.pumpWidget(createTestApp(const QuizScreen(lessonId: 1)));
      await tester.pumpAndSettle();

      // Tap 33-34°C option
      await tester.tap(find.text('33-34°C'));
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Javobni tekshirish'));
      await tester.pumpAndSettle();

      expect(find.text("To'g'ri! Dars muvaffaqiyatli topshirildi."), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('completed_lessons'), contains('1'));
    });

    testWidgets('14. Certificate Screen renders verified farmer credentials', (tester) async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'uz',
        'farmer_name': 'Rustamjon Qodirov',
        'farmer_district': 'Andijon',
      });

      await tester.pumpWidget(createTestApp(const CertificateScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Rustamjon Qodirov'), findsOneWidget);
      expect(find.text('Andijon viloyati'), findsOneWidget);
      expect(find.text('TASDIQLANGAN'), findsOneWidget);
      expect(find.text("Sertifikat bank yoki hamkorlar uchun eksportga tayyor"), findsNothing);

      // Tap Share - opens the native sharing sheet (Android/iOS/Web share UI).
      final shareBtn = find.byIcon(Icons.share_rounded);
      expect(shareBtn, findsOneWidget);
      await tester.tap(shareBtn);
      await tester.pump();
    });

    testWidgets('15. Settings Screen enables language toggle and batch reset', (tester) async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'uz',
        'farmer_name': 'Botir aka',
        'farmer_district': 'Farg\'ona',
        'current_count': 800,
      });

      await tester.pumpWidget(createTestApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Botir aka'), findsOneWidget);
      expect(find.text("Farg'ona | 800 bosh"), findsOneWidget);

      // Toggle to Russian
      await tester.tap(find.text('Русский'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language'), 'ru');
    });

    testWidgets('16. Batch Setup when already onboarded routes directly to /home (Batch Reset Flow)', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_onboarded': true,
        'app_language': 'uz',
      });

      await tester.pumpWidget(createTestApp(const BatchSetupScreen()));
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextFormField, 'Ismingiz / Ferma nomi');
      final countField = find.widgetWithText(TextFormField, "Jo'jalar soni (bosh)");

      await tester.enterText(nameField, 'Otabek Fermer');
      await tester.enterText(countField, '750');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keyingisi'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('farmer_name'), 'Otabek Fermer');
      expect(prefs.getInt('initial_count'), 750);
      expect(prefs.getInt('current_count'), 750);
      expect(find.text('HomeMock'), findsOneWidget);
      expect(find.text('DisclaimerMock'), findsNothing);
    });

    testWidgets('17. Diary Screen evaluates underweight alert and accurate start-of-day mortality rate', (tester) async {
      final day14Arrival = DateTime.now().subtract(const Duration(days: 13));

      // Part A: 1 death out of 100 start-of-day birds (current_count: 99, today_mortality: 1 -> 1.0% <= 1.0% threshold)
      SharedPreferences.setMockInitialValues({
        'counters_date': DailyCounters.todayStamp(),
        'app_language': 'uz',
        'initial_count': 100,
        'current_count': 99,
        'today_mortality': 1,
        'last_weight': 0.0,
        'arrival_date': day14Arrival.toIso8601String(),
      });

      await tester.pumpWidget(createTestApp(const DiaryScreen()));
      await tester.pumpAndSettle();

      // Should NOT trigger a false-positive high-mortality alert
      expect(find.byType(AlertCard), findsNothing);

      // Part B: Severely underweight on Day 14 (350.0g vs 510g norm -> >15% deficit)
      SharedPreferences.setMockInitialValues({
        'counters_date': DailyCounters.todayStamp(),
        'app_language': 'uz',
        'initial_count': 100,
        'current_count': 99,
        'today_mortality': 1,
        'last_weight': 350.0,
        'arrival_date': day14Arrival.toIso8601String(),
      });

      await tester.pumpWidget(createTestApp(const DiaryScreen(key: ValueKey('diary_underweight'))));
      await tester.pumpAndSettle();

      expect(find.byType(AlertCard), findsOneWidget);
      expect(find.textContaining('350g'), findsOneWidget);
    });

    testWidgets('18. English (en) Localization Flow on Dashboard & Quiz Explanation', (tester) async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        'is_onboarded': true,
        'app_language': 'en',
        'farmer_name': 'John Farmer',
        'farmer_district': 'Samarqand',
        'initial_count': 500,
        'current_count': 498,
        'arrival_date': now.subtract(const Duration(days: 6)).toIso8601String(), // Day 7
      });

      await tester.pumpWidget(createTestApp(const HomeScreen()));
      await tester.pumpAndSettle();

      // Verify English greeting and telemetry labels without Uzbek leakage
      expect(find.text('Hello, John Farmer!'), findsOneWidget);
      expect(find.text('Barn Temp'), findsOneWidget);
      expect(find.text('Flock Survival'), findsOneWidget);
      expect(find.text('Daily Care'), findsOneWidget);
      expect(find.text('Assalomu alaykum, John Farmer!'), findsNothing);

      // Pump QuizScreen(lessonId: 1) in English
      await tester.pumpWidget(createTestApp(const QuizScreen(lessonId: 1)));
      await tester.pumpAndSettle();

      expect(
        find.text('To what temperature should the barn be preheated 24 hours before chick arrival?'),
        findsOneWidget,
      );

      await tester.tap(find.text('33-34°C'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Check Answer'));
      await tester.pumpAndSettle();

      expect(find.text('Correct! Lesson completed successfully.'), findsOneWidget);
      expect(
        find.textContaining('Day-old chicks cannot regulate their own body temperature'),
        findsOneWidget,
      );
    });
  });
}
