import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrozen/presentation/screens/home_screen.dart';
import 'package:agrozen/presentation/ui/components.dart';
import '../logical_flow_test.dart' as flow;

void main() {
  for (final (lang, label) in [
    ('uz', 'Vazn'),
    ('ru', 'Вес'),
    ('en', 'Weight'),
  ]) {
    testWidgets('$lang keeps daily recording visible on a 390px phone', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      SharedPreferences.setMockInitialValues({
        'app_language': lang,
        'location_prompt_resolved': true,
        'initial_count': 2000,
        'current_count': 1971,
        'arrival_date': DateTime.now()
            .subtract(const Duration(days: 17))
            .toIso8601String(),
      });
      await tester.pumpWidget(flow.createTestApp(const HomeScreen()));
      await tester.pumpAndSettle();
      final record = find.text(label);
      expect(
        tester.getRect(record).bottom,
        lessThan(tester.getTopLeft(find.byType(NavigationBar)).dy),
      );
      await tester.tap(record);
      await tester.pumpAndSettle();
      expect(find.text('WeightMock'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  for (final lang in ['uz', 'ru', 'en']) {
    for (final scale in [1.0, 2.0]) {
      for (var tab = 0; tab < 4; tab++) {
        testWidgets('$lang tab $tab fits 320px at text scale $scale', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 800);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });
          SharedPreferences.setMockInitialValues({
            'app_language': lang,
            'location_prompt_resolved': true,
            'initial_count': 2000,
            'current_count': 2000,
            if (tab == 1 && scale == 2) 'last_weight': 800.0,
            if (tab == 1 && scale == 2) 'last_weight_day': 18,
            'arrival_date': DateTime.now()
                .subtract(const Duration(days: 17))
                .toIso8601String(),
          });
          await tester.pumpWidget(
            flow.createTestApp(HomeScreen(initialTab: tab)),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          // Inspect expanded details too; the new compact view must retain access.
          if (tab == 1 || tab == 3) {
            final details = find.byType(DetailSection);
            for (var i = 0; i < details.evaluate().length; i++) {
              await tester.ensureVisible(details.at(i));
              await tester.pumpAndSettle();
              final header = find.descendant(
                of: details.at(i),
                matching: find.byType(ExpansionTile),
              );
              await tester.tap(
                find
                    .descendant(of: header, matching: find.byType(ListTile))
                    .first,
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
          }
        });
      }
    }
  }
}
