import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrozen/presentation/widgets/stat_card.dart';
import 'package:agrozen/presentation/widgets/alert_card.dart';
import 'package:agrozen/presentation/widgets/daily_task_card.dart';
import 'package:agrozen/presentation/widgets/language_selector.dart';
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
  });
}
