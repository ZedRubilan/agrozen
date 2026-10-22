import 'package:agrozen/domain/broiler/broiler_grower_library.dart';
import 'package:agrozen/services/farm_store.dart';
import 'package:agrozen/services/loan_report.dart';
import 'package:flutter_test/flutter_test.dart';

FarmSnapshot _farm({
  int initial = 2000,
  int current = 1980,
  int day = 14,
  int recordedDays = 14,
  double? weightG,
  double feedPerDayKg = 0,
}) {
  final arrival = DateTime(2026, 10, 1);
  return FarmSnapshot(
    lang: 'ru',
    farmerName: 'Test',
    district: 'Namangan',
    locality: null,
    initialCount: initial,
    currentCount: current,
    isolatedCount: 0,
    arrivalDate: arrival,
    rawBatchDay: day,
    todayDeaths: 0,
    todayFeedKg: 0,
    lastWeightG: weightG ?? 0,
    lastWeightDay: weightG == null ? null : day,
    locationPromptResolved: true,
    history: [
      for (var d = 1; d <= recordedDays; d++)
        DayRecord(
          date: arrival
              .add(Duration(days: d - 1))
              .toIso8601String()
              .substring(0, 10),
          day: d,
          deaths: d <= (initial - current) ? 1 : 0,
          feedKg: feedPerDayKg,
        ),
    ],
  );
}

void main() {
  group('LoanReport', () {
    test('a well-kept, on-target batch scores low risk', () {
      final target = BroilerGrowerLibrary.specForDay(14).targetWeightG;
      final report = LoanReport.build(
        farm: _farm(weightG: target),
        lessonsDone: 5,
      );
      expect(report.daysRecorded, 14);
      expect(report.diaryCoverage, 1.0);
      expect(report.certified, isTrue);
      expect(report.score, 100);
      expect(report.risk, LoanRisk.low);
    });

    test('heavy losses and an empty diary score high risk', () {
      final report = LoanReport.build(
        farm: _farm(current: 1700, recordedDays: 2),
        lessonsDone: 0,
      );
      // 15 % losses > 2 × 4 % limit → 0; 2 of 14 days → 4; no weight → 5.
      expect(report.factors.firstWhere((f) => f.key == 'survival').points, 0);
      expect(report.risk, LoanRisk.high);
    });

    test('points always add up to at most 100', () {
      final report = LoanReport.build(farm: _farm(), lessonsDone: 3);
      expect(
        report.factors.fold(0, (sum, f) => sum + f.maxPoints),
        LoanReport.maxScore,
      );
      expect(report.score, inInclusiveRange(0, LoanReport.maxScore));
    });

    test('losses are grouped by week of the batch', () {
      final report = LoanReport.build(
        farm: _farm(current: 1990, day: 14),
        lessonsDone: 0,
      );
      // One death on each of days 1–10: 7 in week 1, 3 in week 2.
      expect(report.weeks.map((w) => w.deaths), [7, 3]);
    });

    test('FCR is only shown when feed was logged every day', () {
      final target = BroilerGrowerLibrary.specForDay(14).targetWeightG;
      final partial = LoanReport.build(
        farm: _farm(weightG: target, recordedDays: 10, feedPerDayKg: 60),
        lessonsDone: 0,
      );
      expect(partial.fcr, isNull);

      final full = LoanReport.build(
        farm: _farm(weightG: target, feedPerDayKg: 60),
        lessonsDone: 0,
      );
      expect(full.fcr, isNotNull);
    });
  });
}
