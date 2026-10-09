import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrozen/presentation/widgets/stat_card.dart';
import 'package:agrozen/presentation/widgets/alert_card.dart';
import 'package:agrozen/presentation/widgets/daily_task_card.dart';
import 'package:agrozen/presentation/widgets/language_selector.dart';
import 'package:agrozen/presentation/widgets/loan_profit_tracker_card.dart';
import 'package:agrozen/presentation/widgets/tactile_button.dart';
import 'package:agrozen/presentation/widgets/flock_pathway_card.dart';
import 'package:agrozen/domain/alerts/alert_models.dart';
import 'package:agrozen/data/models/daily_plan.dart';

void main() {
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


