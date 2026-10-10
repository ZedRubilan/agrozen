import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrozen/presentation/widgets/stat_card.dart';
import 'package:agrozen/presentation/widgets/alert_card.dart';
import 'package:agrozen/presentation/widgets/daily_task_card.dart';
import 'package:agrozen/presentation/widgets/language_selector.dart';
import 'package:agrozen/presentation/widgets/loan_profit_tracker_card.dart';
import 'package:agrozen/presentation/widgets/tactile_button.dart';
import 'package:agrozen/presentation/widgets/flock_pathway_card.dart';
import 'package:agrozen/presentation/widgets/desktop_web_shell.dart';
import 'package:agrozen/presentation/widgets/weather_climate_card.dart';
import 'package:agrozen/domain/alerts/alert_models.dart';
import 'package:agrozen/data/models/daily_plan.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Presentation Layer Widget Tests', () {
    testWidgets('StatCard renders title, value, subtitle and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              icon: Icons.pets,
              title: 'Поголовье',
              value: '495',
              subtitle: 'из 500',
            ),
          ),
        ),
      );

      expect(find.text('Поголовье'), findsOneWidget);
      expect(find.text('495'), findsOneWidget);
      expect(find.text('из 500'), findsOneWidget);
      expect(find.byIcon(Icons.pets), findsOneWidget);
    });

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

    testWidgets('DailyTaskCard renders day, tasks and temperature badge', (tester) async {
      const plan = DailyPlan(
        day: 5,
        tasksRu: 'Проверьте температуру 32C и поилки.',
        tasksUz: "32C harorat va suv idishlarini tekshiring.",
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DailyTaskCard(
              plan: plan,
              language: 'uz',
              targetTemperature: 32,
            ),
          ),
        ),
      );

      expect(find.text('5-kun'), findsOneWidget);
      expect(find.text('32°C'), findsOneWidget);
      expect(find.text('32C harorat va suv idishlarini tekshiring.'), findsOneWidget);
    });

    testWidgets('LanguageSelector renders both Uzbek and Russian options', (tester) async {
      String selected = 'uz';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return LanguageSelector(
                  currentLanguage: selected,
                  onLanguageChanged: (lang) => setState(() => selected = lang),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text("O'zbekcha"), findsOneWidget);
      expect(find.text('Русский'), findsOneWidget);

      await tester.tap(find.text('Русский'));
      await tester.pumpAndSettle();

      expect(selected, 'ru');
    });

    testWidgets('LoanProfitTrackerCard renders financial debt and profit estimates', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoanProfitTrackerCard(
              currentCount: 495,
              initialCount: 500,
              batchDay: 14,
              language: 'uz',
              bankLoanUz: 15000000.0,
            ),
          ),
        ),
      );

      expect(find.text("Agrokredit va Kutilayotgan Foyda"), findsOneWidget);
      expect(find.text("Bank krediti"), findsOneWidget);
      expect(find.text("15.0 mln"), findsOneWidget);
      expect(find.text("Sof foyda"), findsOneWidget);
    });

    testWidgets('TactileButton renders child and invokes callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TactileButton(
              onPressed: () => tapped = true,
              child: const Text('Ovozli rejim'),
            ),
          ),
        ),
      );

      expect(find.text('Ovozli rejim'), findsOneWidget);
      await tester.tap(find.text('Ovozli rejim'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('TactileButton pressing down and releasing preserves outer RenderBox height with zero layout shift', (tester) async {
      const double buttonHeight = 56.0;
      const double buttonDepth = 4.0;
      const double expectedOuterHeight = buttonHeight + buttonDepth;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TactileButton(
                height: buttonHeight,
                depth: buttonDepth,
                onPressed: () {},
                child: const Text('Saqlash'),
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(TactileButton);
      final initialSize = tester.getSize(buttonFinder);
      expect(initialSize.height, expectedOuterHeight);

      // Press down and pump animation frame
      final gesture = await tester.press(buttonFinder);
      await tester.pump(const Duration(milliseconds: 70));

      final pressedSize = tester.getSize(buttonFinder);
      expect(pressedSize.height, expectedOuterHeight);

      // Release and settle
      await gesture.up();
      await tester.pumpAndSettle();

      final releasedSize = tester.getSize(buttonFinder);
      expect(releasedSize.height, expectedOuterHeight);
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

    testWidgets('WeatherClimateCard renders without overflow and displays Ross-308 target temperature and day pills', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WeatherClimateCard(
                district: 'Samarqand',
                batchDay: 14,
                targetHouseTemp: 26.0,
                language: 'uz',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Samarqand'), findsOneWidget);
      expect(find.text('14-kun • Ross-308'), findsOneWidget);
      expect(find.text('26°C'), findsOneWidget);
      expect(find.text('D-2'), findsOneWidget);
      expect(find.text('D-1'), findsOneWidget);
      expect(find.text('Bugun'), findsOneWidget);
      expect(find.text('D+1'), findsOneWidget);
      expect(find.text('D+2'), findsOneWidget);
      expect(find.text('D+3'), findsOneWidget);
    });

    testWidgets('FlockPathwayCard renders 42-day milestone pathway', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlockPathwayCard(
              batchDay: 14,
              language: 'uz',
            ),
          ),
        ),
      );

      expect(find.text("14-kun / 42 kundan"), findsOneWidget);
      expect(find.text("33%"), findsOneWidget);
      expect(find.text("Start"), findsOneWidget);
      expect(find.text("O'sish"), findsOneWidget);
      expect(find.text("Finish"), findsOneWidget);
      expect(find.text("Hosil"), findsOneWidget);
    });
  });
}

