import 'dart:convert';
import 'dart:io';
import 'package:agrozen/domain/broiler/broiler_grower_library.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every screen, the alert engine and the AI context must show the farmer the
/// same per-day targets. BroilerGrowerLibrary mirrors knowledge/norms.json;
/// this test fails the moment the two drift apart.
void main() {
  test('BroilerGrowerLibrary matches knowledge/norms.json for days 1–42', () {
    final json = jsonDecode(File('knowledge/norms.json').readAsStringSync())
        as Map<String, dynamic>;
    final daily = json['daily_norms'] as Map<String, dynamic>;
    expect(daily.length, 42);

    for (var day = 1; day <= 42; day++) {
      final norm = daily['$day'] as Map<String, dynamic>;
      final spec = BroilerGrowerLibrary.specForDay(day);
      final reason = 'day $day';
      expect(spec.targetWeightG, (norm['weight_g'] as num).toDouble(), reason: reason);
      expect(spec.dailyFeedPerBirdG, (norm['feed_g'] as num).toDouble(), reason: reason);
      expect(spec.dailyWaterPerBirdMl, (norm['water_ml'] as num).toDouble(), reason: reason);
      expect(spec.targetTempC, (norm['temp_c'] as num).toDouble(), reason: reason);
    }
  });
}
