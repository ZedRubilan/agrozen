import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrozen/config/theme.dart';
import 'package:agrozen/data/models/daily_plan.dart';
import 'package:agrozen/data/models/weather_data.dart';
import 'package:agrozen/domain/alerts/alert_models.dart';
import 'package:agrozen/presentation/ui/components.dart';
import 'package:agrozen/presentation/ui/format.dart';
import 'package:agrozen/presentation/widgets/agro_icons.dart';
import 'package:agrozen/presentation/widgets/alert_card.dart';
import 'package:agrozen/presentation/widgets/desktop_web_shell.dart';
import 'package:agrozen/presentation/widgets/task_checklist_card.dart';
import 'package:agrozen/presentation/widgets/weather_summary_card.dart';

/// Runs with "reduce motion" so looping animations (weather scene) settle.
Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Presentation Layer Widget Tests', () {
    testWidgets('AlertCard renders warning and critical severity properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AlertCard(
              message: "Nobodlik me'yordan oshdi!",
              severity: AlertSeverity.critical,
              vetName: 'Dr. Karimov',
              vetPhone: '+998901234501',
            ),
          ),
        ),
      );

      expect(find.text("Nobodlik me'yordan oshdi!"), findsOneWidget);
      expect(find.text('XAVF! / ОПАСНОСТЬ!'), findsOneWidget);
      expect(find.byIcon(Icons.phone_in_talk), findsOneWidget);
    });

    testWidgets('AlertCard renders localized single-language headers for uz, ru, and en', (tester) async {
      // 1. Uzbek ('uz') critical & warning
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AlertCard(
                  message: 'Uzbek critical',
                  severity: AlertSeverity.critical,
                  locale: 'uz',
                ),
                AlertCard(
                  message: 'Uzbek warning',
                  severity: AlertSeverity.warning,
                  locale: 'uz',
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('XAVF!'), findsOneWidget);
      expect(find.text('OGOHLANTIRISH'), findsOneWidget);

      // 2. Russian ('ru') critical & warning
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AlertCard(
                  message: 'Russian critical',
                  severity: AlertSeverity.critical,
                  locale: 'ru',
                ),
                AlertCard(
                  message: 'Russian warning',
                  severity: AlertSeverity.warning,
                  locale: 'ru',
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('ОПАСНОСТЬ!'), findsOneWidget);
      expect(find.text('ПРЕДУПРЕЖДЕНИЕ'), findsOneWidget);

      // 3. English ('en') critical & warning
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AlertCard(
                  message: 'English critical',
                  severity: AlertSeverity.critical,
                  locale: 'en',
                ),
                AlertCard(
                  message: 'English warning',
                  severity: AlertSeverity.warning,
                  locale: 'en',
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('CRITICAL ALERT'), findsOneWidget);
      expect(find.text('WARNING'), findsOneWidget);
    });

    testWidgets('DesktopWebShell renders cleanly on mobile (400x800) and desktop (1200x900) viewports without overflow', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Mobile viewport (400x800)
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 800);

      await tester.pumpWidget(
        const MaterialApp(
          home: DesktopWebShell(
            child: Scaffold(
              body: Center(child: Text('ShellContent')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ShellContent'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 2. Desktop viewport (1200x900)
      tester.view.physicalSize = const Size(1200, 900);

      await tester.pumpWidget(
        const MaterialApp(
          home: DesktopWebShell(
            child: Scaffold(
              body: Center(child: Text('ShellContentDesktop')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ShellContentDesktop'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AgroChickIcon renders natural rounded photographic logo inside ClipOval', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AgroChickIcon(size: 72),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AgroChickIcon), findsOneWidget);
      expect(find.byType(ClipOval), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('MetricTile and MetricGrid render label, value and caption', (tester) async {
      await tester.pumpWidget(_wrap(const MetricGrid(children: [
        MetricTile(icon: Icons.thermostat_rounded, label: 'House', value: '26.5°C', caption: 'At bird level'),
        MetricTile(icon: Icons.grain_rounded, label: 'Feed', value: '27 kg'),
        MetricTile(icon: Icons.water_drop_outlined, label: 'Water', value: '54 L'),
      ])));
      expect(find.text('House'), findsOneWidget);
      expect(find.text('26.5°C'), findsOneWidget);
      expect(find.text('At bird level'), findsOneWidget);
      expect(find.text('54 L'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('NoticeBanner shows title, message, actions and close', (tester) async {
      var closed = false;
      await tester.pumpWidget(_wrap(NoticeBanner(
        tone: Tone.warning,
        icon: Icons.info_outline,
        title: 'Heads up',
        message: 'Something to know',
        onClose: () => closed = true,
        actions: [FilledButton(onPressed: () {}, child: const Text('Do it'))],
      )));
      expect(find.text('Heads up'), findsOneWidget);
      expect(find.text('Something to know'), findsOneWidget);
      expect(find.text('Do it'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(closed, isTrue);
    });

    testWidgets('ListGroup rows are tappable', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_wrap(ListGroup(children: [
        ListRow(icon: Icons.person, title: 'Name', subtitle: 'Edit', onTap: () => tapped++),
        const ListRow(icon: Icons.info, title: 'About'),
      ])));
      await tester.tap(find.text('Name'));
      expect(tapped, 1);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('PrimaryButton shows a spinner and ignores taps while busy', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(PrimaryButton(label: 'Save', busy: true, onPressed: () => taps++)));
      expect(find.text('Save'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      expect(taps, 0);
    });

    testWidgets('TaskChecklistCard ticks tasks and persists them per day', (tester) async {
      await tester.pumpWidget(_wrap(const TaskChecklistCard(day: 5, tasks: ['Check water', 'Weigh birds', 'Clean drinkers'])));
      await tester.pumpAndSettle();
      expect(find.text('0/3'), findsOneWidget);

      await tester.tap(find.text('Weigh birds'));
      await tester.pumpAndSettle();
      expect(find.text('1/3'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('plan_tasks_done_5'), ['1']);

      await tester.tap(find.text('Weigh birds'));
      await tester.pumpAndSettle();
      expect(find.text('0/3'), findsOneWidget);
    });

    testWidgets('WeatherSummaryCard compares outside weather with the barn and expands', (tester) async {
      await tester.pumpWidget(_wrap(SingleChildScrollView(
        child: WeatherSummaryCard(
          district: 'Samarqand',
          locationLabel: 'Samarqand',
          batchDay: 14,
          targetHouseTemp: 26.5,
          language: 'en',
          loader: (d) async => WeatherData(
            district: d,
            temperature: 36,
            humidity: 30,
            windSpeed: 10,
            condition: 'hot',
            timestamp: DateTime.now(),
            isLive: true,
          ),
        ),
      )));
      await tester.pumpAndSettle();

      expect(find.text('Outside 36°C'), findsOneWidget);
      expect(find.text('Heat Stress Warning'), findsOneWidget);
      expect(find.text('Ventilation'), findsNothing);

      await tester.tap(find.text('Outside 36°C'));
      await tester.pumpAndSettle();
      expect(find.text('Ventilation'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
    });

    testWidgets('WeatherSummaryCard marks offline estimates', (tester) async {
      await tester.pumpWidget(_wrap(WeatherSummaryCard(
        district: 'Toshkent',
        locationLabel: 'Toshkent',
        batchDay: 3,
        targetHouseTemp: 31.5,
        language: 'uz',
        loader: (d) async => WeatherData.fallback(d),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Taxminiy'), findsOneWidget);
    });

    test('Fmt formats numbers and units consistently in all three languages', () {
      expect(Fmt.num(27), '27');
      expect(Fmt.num(27.25), '27.3');
      expect(Fmt.grouped(12500), '12 500');
      expect(const Fmt('uz').kg(13.4), '13.4 kg');
      expect(const Fmt('ru').kg(13.4), '13.4 кг');
      expect(const Fmt('en').day(7), 'Day 7');
      expect(const Fmt('uz').day(7), '7-kun');
      expect(const Fmt('ru').days(1), '1 день');
      expect(const Fmt('ru').days(3), '3 дня');
      expect(const Fmt('ru').days(11), '11 дней');
      expect(const Fmt('ru').days(21), '21 день');
    });

    test('DailyPlan splits a paragraph into checklist items', () {
      const plan = DailyPlan(
        day: 1,
        tasksRu: 'Подготовьте брудер. Проверьте температуру (32-33°C). Включите свет.',
        tasksUz: "Bruderni tayyorlang. Haroratni tekshiring (32-33°C). 2 soatdan so'ng yem bering.",
        tasksEn: 'Prepare the brooder.\nProvide light.',
      );
      expect(plan.taskList('ru'), hasLength(3));
      expect(plan.taskList('uz').last, "2 soatdan so'ng yem bering.");
      expect(plan.taskList('en'), ['Prepare the brooder.', 'Provide light.']);
    });
  });
}
