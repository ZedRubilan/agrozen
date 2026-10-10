import 'package:agrozen/domain/alerts/alert_engine.dart';
import 'package:agrozen/domain/alerts/alert_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlertEngine', () {
    late NormsData testNorms;
    late AlertEngine alertEngine;

    setUp(() {
      testNorms = const NormsData(
        mortalityThresholdPercent: 1.0,
        weeklyWeightTargets: {
          7: 200.0,
          14: 450.0,
          21: 900.0,
          28: 1500.0,
          35: 2200.0,
          42: 2800.0,
        },
        weightDeviationPercent: 10.0,
        dailyFeedPerBird: {
          1: 15.0,
          7: 35.0,
          14: 65.0,
        },
        temperatureTargets: {
          1: 33.0,
          7: 30.0,
          14: 27.0,
        },
      );
      alertEngine = AlertEngine(testNorms);
    });

    group('checkMortality', () {
      test('mortality below threshold -> no alert', () {
        // 5 deaths out of 1000 = 0.5% (threshold is 1.0%)
        final alert = alertEngine.checkMortality(
          deaths: 5,
          currentCount: 1000,
        );
        expect(alert, isNull);
      });

      test('mortality exactly at threshold -> no alert', () {
        // 10 deaths out of 1000 = 1.0%
        final alert = alertEngine.checkMortality(
          deaths: 10,
          currentCount: 1000,
        );
        expect(alert, isNull);
      });

      test('mortality above threshold -> warning alert', () {
        // 15 deaths out of 1000 = 1.5% (threshold is 1.0%, 3x threshold is 3.0%)
        final alert = alertEngine.checkMortality(
          deaths: 15,
          currentCount: 1000,
        );
        expect(alert, isNotNull);
        expect(alert!.type, equals(AlertType.highMortality));
        expect(alert.severity, equals(AlertSeverity.warning));
        expect(alert.actualValue, closeTo(1.5, 0.01));
        expect(alert.threshold, equals(1.0));
        expect(alert.messageRu, contains('1.5%'));
        expect(alert.messageUz, contains('1.5%'));
      });

      test('mortality way above threshold (> 3x) -> critical alert', () {
        // 35 deaths out of 1000 = 3.5% (threshold is 1.0%, 3x is 3.0%)
        final alert = alertEngine.checkMortality(
          deaths: 35,
          currentCount: 1000,
        );
        expect(alert, isNotNull);
        expect(alert!.type, equals(AlertType.highMortality));
        expect(alert.severity, equals(AlertSeverity.critical));
        expect(alert.actualValue, closeTo(3.5, 0.01));
        expect(alert.threshold, equals(1.0));
        expect(alert.messageRu, contains('35 голов'));
        expect(alert.messageUz, contains('35 bosh'));
      });

      test('zero current count -> no alert (no division by zero)', () {
        final alert = alertEngine.checkMortality(
          deaths: 10,
          currentCount: 0,
        );
        expect(alert, isNull);
      });

      test('negative current count -> no alert', () {
        final alert = alertEngine.checkMortality(
          deaths: 10,
          currentCount: -50,
        );
        expect(alert, isNull);
      });

      test('zero deaths -> no alert', () {
        final alert = alertEngine.checkMortality(
          deaths: 0,
          currentCount: 1000,
        );
        expect(alert, isNull);
      });

      test('negative deaths -> no alert', () {
        final alert = alertEngine.checkMortality(
          deaths: -5,
          currentCount: 1000,
        );
        expect(alert, isNull);
      });
    });

    group('checkWeight', () {
      test('weight at norm -> no alert', () {
        // Day 7 target is 200g
        final alert = alertEngine.checkWeight(
          weightGrams: 200.0,
          batchDay: 7,
        );
        expect(alert, isNull);
      });

      test('weight above norm -> no alert', () {
        final alert = alertEngine.checkWeight(
          weightGrams: 220.0,
          batchDay: 7,
        );
        expect(alert, isNull);
      });

      test('weight slightly below norm within deviation allowance -> no alert', () {
        // 190g on 200g norm = 5% deviation <= 10%
        final alert = alertEngine.checkWeight(
          weightGrams: 190.0,
          batchDay: 7,
        );
        expect(alert, isNull);
      });

      test('weight 15% below norm -> warning alert', () {
        // Day 7 target = 200g, 15% below = 170g.
        // Deviation percent is 10%, 2x is 20%.
        // 15% > 10% and <= 20% -> warning
        final alert = alertEngine.checkWeight(
          weightGrams: 170.0,
          batchDay: 7,
        );
        expect(alert, isNotNull);
        expect(alert!.type, equals(AlertType.lowWeight));
        expect(alert.severity, equals(AlertSeverity.warning));
        expect(alert.actualValue, equals(170.0));
        expect(alert.threshold, equals(200.0));
        expect(alert.messageRu, contains('170г'));
        expect(alert.messageUz, contains('170g'));
      });

      test('weight 30% below norm -> critical alert', () {
        // Day 7 target = 200g, 30% below = 140g.
        // Deviation 30% > 20% (2x threshold) -> critical
        final alert = alertEngine.checkWeight(
          weightGrams: 140.0,
          batchDay: 7,
        );
        expect(alert, isNotNull);
        expect(alert!.type, equals(AlertType.lowWeight));
        expect(alert.severity, equals(AlertSeverity.critical));
        expect(alert.actualValue, equals(140.0));
        expect(alert.threshold, equals(200.0));
      });

      test('weight check for day with no exact checkpoint -> uses previous checkpoint', () {
        // Day 10 has no direct checkpoint. Closest checkpoint <= 10 is day 7 (200g).
        // 160g on 200g norm = 20% deviation > 10% -> warning alert
        final alert = alertEngine.checkWeight(
          weightGrams: 160.0,
          batchDay: 10,
        );
        expect(alert, isNotNull);
        expect(alert!.threshold, equals(200.0));
        expect(alert.type, equals(AlertType.lowWeight));
      });

      test('day before first checkpoint has no target -> no alert', () {
        // Day 3 is before first checkpoint (day 7)
        final alert = alertEngine.checkWeight(
          weightGrams: 40.0,
          batchDay: 3,
        );
        expect(alert, isNull);
      });

      test('zero or negative weight -> no alert', () {
        expect(alertEngine.checkWeight(weightGrams: 0, batchDay: 7), isNull);
        expect(alertEngine.checkWeight(weightGrams: -100, batchDay: 7), isNull);
      });
    });

    group('checkTemperature', () {
      test('temperature within threshold -> no alert', () {
        // Day 7 target is 30.0°C, default tempDeviationCelsius is 2.0°C
        expect(
          alertEngine.checkTemperature(batchDay: 7, actualTempCelsius: 31.5),
          isNull,
        );
      });

      test('temperature above threshold -> warning highTemperature alert', () {
        // Day 7 target is 30.0°C, actual 33.0°C -> diff = 3.0°C (> 2.0°C, <= 4.0°C)
        final alert = alertEngine.checkTemperature(
          batchDay: 7,
          actualTempCelsius: 33.0,
        );
        expect(alert, isNotNull);
        expect(alert!.type, equals(AlertType.highTemperature));
        expect(alert.severity, equals(AlertSeverity.warning));
        expect(alert.actualValue, equals(33.0));
        expect(alert.threshold, equals(30.0));
        expect(alert.messageRu, contains('выше нормы'));
        expect(alert.messageUz, contains('yuqori'));
        expect(alert.messageEn, contains('exceeds target'));
      });

      test('temperature far below threshold (> 2x deviation) -> critical highTemperature alert', () {
        // Day 7 target is 30.0°C, actual 24.5°C -> diff = 5.5°C (> 4.0°C)
        final alert = alertEngine.checkTemperature(
          batchDay: 7,
          actualTempCelsius: 24.5,
        );
        expect(alert, isNotNull);
        expect(alert!.type, equals(AlertType.highTemperature));
        expect(alert.severity, equals(AlertSeverity.critical));
        expect(alert.messageRu, contains('ниже нормы'));
        expect(alert.messageUz, contains('past'));
        expect(alert.messageEn, contains('below target'));
      });
    });

    group('checkCumulativeMortality', () {
      test('cumulative mortality at or below 4.0% threshold -> no alert', () {
        // 40 out of 1000 = 4.0%
        expect(
          alertEngine.checkCumulativeMortality(
            totalDeaths: 40,
            initialCount: 1000,
            batchDay: 21,
          ),
          isNull,
        );
      });

      test('cumulative mortality above 4.0% threshold -> warning alert', () {
        // 50 out of 1000 = 5.0% (> 4.0%, <= 8.0%)
        final alert = alertEngine.checkCumulativeMortality(
          totalDeaths: 50,
          initialCount: 1000,
          batchDay: 21,
        );
        expect(alert, isNotNull);
        expect(alert!.type, equals(AlertType.highMortality));
        expect(alert.severity, equals(AlertSeverity.warning));
        expect(alert.actualValue, closeTo(5.0, 0.01));
        expect(alert.threshold, equals(4.0));
        expect(alert.messageRu, contains('Общий падёж'));
        expect(alert.messageUz, contains('umumiy nobodlik'));
        expect(alert.messageEn, contains('Cumulative mortality'));
      });

      test('cumulative mortality above 2x threshold (> 8.0%) -> critical alert', () {
        // 90 out of 1000 = 9.0%
        final alert = alertEngine.checkCumulativeMortality(
          totalDeaths: 90,
          initialCount: 1000,
          batchDay: 28,
        );
        expect(alert, isNotNull);
        expect(alert!.severity, equals(AlertSeverity.critical));
      });
    });

    group('runAllChecks', () {
      test('runAllChecks with multiple alerts', () {
        // Day 7: high mortality (20/1000 = 2%) AND low weight (160g vs 200g)
        final alerts = alertEngine.runAllChecks(
          batchDay: 7,
          deaths: 20,
          currentCount: 1000,
          weightGrams: 160.0,
        );
        expect(alerts.length, equals(2));
        expect(alerts.any((a) => a.type == AlertType.highMortality), isTrue);
        expect(alerts.any((a) => a.type == AlertType.lowWeight), isTrue);
      });

      test('runAllChecks with no alerts', () {
        // Day 7: normal mortality (5/1000 = 0.5%) AND normal weight (205g)
        final alerts = alertEngine.runAllChecks(
          batchDay: 7,
          deaths: 5,
          currentCount: 1000,
          weightGrams: 205.0,
        );
        expect(alerts, isEmpty);
      });

      test('runAllChecks with only mortality alert', () {
        final alerts = alertEngine.runAllChecks(
          batchDay: 7,
          deaths: 25,
          currentCount: 1000,
          weightGrams: 200.0,
        );
        expect(alerts.length, equals(1));
        expect(alerts.first.type, equals(AlertType.highMortality));
      });

      test('runAllChecks with only weight alert', () {
        final alerts = alertEngine.runAllChecks(
          batchDay: 7,
          deaths: 2,
          currentCount: 1000,
          weightGrams: 150.0,
        );
        expect(alerts.length, equals(1));
        expect(alerts.first.type, equals(AlertType.lowWeight));
      });

      test('runAllChecks when optional parameters are null', () {
        final alerts = alertEngine.runAllChecks(batchDay: 7);
        expect(alerts, isEmpty);
      });
    });

    group('NormsData', () {
      test('fromJson parses norms structure correctly', () {
        final json = {
          'mortality': {'daily_threshold_percent': 1.2},
          'weight': {
            'weekly_targets_grams': {'7': 185, '14': 440, '21': 890},
            'deviation_percent': 12.0,
          },
          'feed': {
            'daily_grams_per_bird': {'1': 16.5, '7': 38.0},
          },
          'temperature': {
            'targets_celsius': {'1': 32.5, '7': 29.5},
          },
        };

        final norms = NormsData.fromJson(json);
        expect(norms.mortalityThresholdPercent, equals(1.2));
        expect(norms.weightDeviationPercent, equals(12.0));
        expect(norms.weeklyWeightTargets[7], equals(185.0));
        expect(norms.weeklyWeightTargets[14], equals(440.0));
        expect(norms.dailyFeedPerBird[1], equals(16.5));
        expect(norms.temperatureTargets[1], equals(32.5));
      });

      test('weightTargetForDay finds closest previous checkpoint', () {
        expect(testNorms.weightTargetForDay(6), isNull);
        expect(testNorms.weightTargetForDay(7), equals(200.0));
        expect(testNorms.weightTargetForDay(10), equals(200.0));
        expect(testNorms.weightTargetForDay(14), equals(450.0));
        expect(testNorms.weightTargetForDay(20), equals(450.0));
        expect(testNorms.weightTargetForDay(45), equals(2800.0));
      });

      test('feedTargetForDay returns exact or closest previous checkpoint', () {
        expect(testNorms.feedTargetForDay(1), equals(15.0));
        expect(testNorms.feedTargetForDay(4), equals(15.0));
        expect(testNorms.feedTargetForDay(7), equals(35.0));
        expect(testNorms.feedTargetForDay(14), equals(65.0));
        expect(testNorms.feedTargetForDay(20), equals(65.0));
      });

      test('AlertResult equality based on props', () {
        const result1 = AlertResult(
          type: AlertType.highMortality,
          severity: AlertSeverity.warning,
          actualValue: 1.5,
          threshold: 1.0,
          messageRu: 'msg1',
        );
        const result2 = AlertResult(
          type: AlertType.highMortality,
          severity: AlertSeverity.warning,
          actualValue: 1.5,
          threshold: 1.0,
          messageRu: 'msg2', // different message, but props are type, severity, actualValue, threshold
        );
        expect(result1, equals(result2));
      });
    });
  });
}
