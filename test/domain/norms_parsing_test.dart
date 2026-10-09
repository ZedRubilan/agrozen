import 'dart:convert';
import 'dart:io';

import 'package:agrozen/domain/alerts/alert_engine.dart';
import 'package:agrozen/domain/alerts/alert_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the link between `knowledge/norms.json` and the deterministic
/// AlertEngine. The norms file is edited by the veterinarian, so the app must
/// never hardcode a second copy of these numbers.
void main() {
  late Map<String, dynamic> rawNorms;
  late NormsData norms;

  setUpAll(() {
    rawNorms = jsonDecode(
      File('knowledge/norms.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    norms = NormsData.fromJson(rawNorms);
  });

  group('NormsData parses the SHIPPED norms.json schema', () {
    test('critical thresholds are read, not defaulted', () {
      final critical = rawNorms['critical_thresholds'] as Map<String, dynamic>;

      expect(
        norms.mortalityThresholdPercent,
        (critical['daily_mortality_alert_percent'] as num).toDouble(),
      );
      expect(
        norms.weightDeviationPercent,
        (critical['weight_deficit_alert_percent'] as num).toDouble(),
      );
    });

    test('all 42 daily weight norms are loaded', () {
      final daily = rawNorms['daily_norms'] as Map<String, dynamic>;
      expect(norms.dailyWeightTargets.length, daily.length);
      expect(norms.dailyWeightTargets.length, 42);
    });

    test('all 42 daily temperature norms are loaded', () {
      final daily = rawNorms['daily_norms'] as Map<String, dynamic>;
      expect(norms.dailyTemperatureTargets.length, daily.length);
    });

    test('weekly norms are keyed by the last day of the week', () {
      final weekly = rawNorms['weekly_norms'] as List;
      for (final entry in weekly) {
        final week = (entry as Map)['week'] as int;
        final target = (entry['target_weight_g'] as num).toDouble();
        expect(norms.weeklyWeightTargets[week * 7], target);
      }
    });

    test('weightTargetForDay returns the exact daily norm for every day', () {
      final daily = rawNorms['daily_norms'] as Map<String, dynamic>;
      for (final entry in daily.entries) {
        final day = int.parse(entry.key);
        final expected = ((entry.value as Map)['weight_g'] as num).toDouble();
        expect(
          norms.weightTargetForDay(day),
          expected,
          reason: 'day $day should use the exact daily norm',
        );
      }
    });

    test('temperatureTargetForDay reads daily norms', () {
      final daily = rawNorms['daily_norms'] as Map<String, dynamic>;
      final day21 = (daily['21'] as Map)['temp_c'] as num;
      expect(norms.temperatureTargetForDay(21), day21.toDouble());
    });
  });

  group('NormsData is defensive against malformed input', () {
    test('empty json does not throw and uses safe defaults', () {
      final parsed = NormsData.fromJson(const {});
      expect(parsed.mortalityThresholdPercent, 1.0);
      expect(parsed.weightDeviationPercent, 15.0);
      expect(parsed.weeklyWeightTargets, isEmpty);
      expect(parsed.weightTargetForDay(7), isNull);
    });

    test('partial json keeps defaults for missing sections', () {
      final parsed = NormsData.fromJson({
        'critical_thresholds': {'daily_mortality_alert_percent': 0.8},
      });
      expect(parsed.mortalityThresholdPercent, 0.8);
      expect(parsed.weightDeviationPercent, 15.0);
    });

    test('legacy flat schema still parses', () {
      final parsed = NormsData.fromJson({
        'mortality': {'daily_threshold_percent': 1.2},
        'weight': {
          'weekly_targets_grams': {'7': 185, '14': 440},
          'deviation_percent': 12.0,
        },
        'feed': {'daily_grams_per_bird': {'1': 16.5}},
        'temperature': {'targets_celsius': {'1': 32.5}},
      });

      expect(parsed.mortalityThresholdPercent, 1.2);
      expect(parsed.weightDeviationPercent, 12.0);
      expect(parsed.weeklyWeightTargets[14], 440.0);
      expect(parsed.dailyFeedPerBird[1], 16.5);
      expect(parsed.temperatureTargets[1], 32.5);
    });

    test('non-numeric values are skipped instead of crashing', () {
      final parsed = NormsData.fromJson({
        'critical_thresholds': {'daily_mortality_alert_percent': 'oops'},
        'weekly_norms': [
          {'week': 'x', 'target_weight_g': 'y'},
          {'week': 1, 'target_weight_g': 180},
        ],
        'daily_norms': {
          '1': {'weight_g': 42, 'temp_c': 32.5},
          'bad': {'weight_g': 1},
        },
      });

      expect(parsed.mortalityThresholdPercent, 1.0);
      expect(parsed.weeklyWeightTargets[7], 180.0);
      expect(parsed.dailyWeightTargets[1], 42.0);
      expect(parsed.dailyWeightTargets.length, 1);
    });

    test('weightTargetForDay falls back to the previous weekly checkpoint', () {
      final sparse = NormsData(
        mortalityThresholdPercent: 1.0,
        weeklyWeightTargets: {7: 185.0, 14: 465.0},
        weightDeviationPercent: 15.0,
        dailyFeedPerBird: const {},
        temperatureTargets: const {},
      );

      expect(sparse.weightTargetForDay(7), 185.0);
      expect(sparse.weightTargetForDay(13), 185.0);
      expect(sparse.weightTargetForDay(14), 465.0);
      expect(sparse.weightTargetForDay(1), isNull,
          reason: 'no checkpoint at or before day 1');
    });
  });

  group('AlertEngine with real norms', () {
    late AlertEngine engine;

    setUp(() {
      engine = AlertEngine(norms);
    });

    test('day-42 bird at the norm does not alert', () {
      final target = norms.weightTargetForDay(42)!;
      expect(engine.checkWeight(weightGrams: target, batchDay: 42), isNull);
    });

    test('day-42 bird 20% below the norm alerts', () {
      final target = norms.weightTargetForDay(42)!;
      final alert =
          engine.checkWeight(weightGrams: target * 0.80, batchDay: 42);
      expect(alert, isNotNull);
      expect(alert!.type, AlertType.lowWeight);
      expect(alert.threshold, target);
    });

    test('day-14 uses the real 510g norm, not a hardcoded 500g', () {
      expect(norms.weightTargetForDay(14), 510.0);
      // 440g is 13.7% below 510 -> below the 15% threshold -> no alert.
      expect(engine.checkWeight(weightGrams: 440, batchDay: 14), isNull);
      // 430g is 15.7% below 510 -> alert.
      expect(engine.checkWeight(weightGrams: 430, batchDay: 14), isNotNull);
    });

    test('mortality threshold comes from the norms file', () {
      expect(norms.mortalityThresholdPercent, 1.0);
      // 10 of 1000 = exactly 1.0% -> not above threshold -> no alert.
      expect(engine.checkMortality(deaths: 10, currentCount: 1000), isNull);
      expect(engine.checkMortality(deaths: 11, currentCount: 1000), isNotNull);
    });
  });
}

