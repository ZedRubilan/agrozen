import 'package:agrozen/domain/scheduler/day_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DayCalculator', () {
    final arrivalDate = DateTime(2026, 10, 1);

    group('calculateBatchDay', () {
      test('returns day 1 on arrival date itself', () {
        final now = DateTime(2026, 10, 1, 14, 30);
        final batchDay = DayCalculator.calculateBatchDay(arrivalDate, now: now);
        expect(batchDay, equals(1));
      });

      test('returns day 2 on the next day', () {
        final now = DateTime(2026, 10, 2, 8, 0);
        final batchDay = DayCalculator.calculateBatchDay(arrivalDate, now: now);
        expect(batchDay, equals(2));
      });

      test('returns day 42 on the 42nd day', () {
        final now = arrivalDate.add(const Duration(days: 41));
        final batchDay = DayCalculator.calculateBatchDay(arrivalDate, now: now);
        expect(batchDay, equals(42));
      });

      test('returns day 43 after the 42-day cycle', () {
        final now = arrivalDate.add(const Duration(days: 42));
        final batchDay = DayCalculator.calculateBatchDay(arrivalDate, now: now);
        expect(batchDay, equals(43));
      });

      test('returns day 0 one day before arrival date', () {
        final now = DateTime(2026, 9, 30);
        final batchDay = DayCalculator.calculateBatchDay(arrivalDate, now: now);
        expect(batchDay, equals(0));
      });

      test('returns negative day before arrival date', () {
        final now = DateTime(2026, 9, 28);
        final batchDay = DayCalculator.calculateBatchDay(arrivalDate, now: now);
        expect(batchDay, equals(-2));
      });

      test('uses DateTime.now() if now is omitted', () {
        final today = DateTime.now();
        final batchDay = DayCalculator.calculateBatchDay(today);
        expect(batchDay, equals(1));
      });
    });

    group('isBatchActive', () {
      test('returns true on day 1 (arrival date)', () {
        final now = arrivalDate;
        expect(DayCalculator.isBatchActive(arrivalDate, now: now), isTrue);
      });

      test('returns true on mid-cycle days (e.g., day 15, day 28)', () {
        final day15 = arrivalDate.add(const Duration(days: 14));
        final day28 = arrivalDate.add(const Duration(days: 27));
        expect(DayCalculator.isBatchActive(arrivalDate, now: day15), isTrue);
        expect(DayCalculator.isBatchActive(arrivalDate, now: day28), isTrue);
      });

      test('returns true on exactly day 42', () {
        final day42 = arrivalDate.add(const Duration(days: 41));
        expect(DayCalculator.isBatchActive(arrivalDate, now: day42), isTrue);
      });

      test('returns false on day 43 (batch ended)', () {
        final day43 = arrivalDate.add(const Duration(days: 42));
        expect(DayCalculator.isBatchActive(arrivalDate, now: day43), isFalse);
      });

      test('returns false before arrival (day 0 or negative)', () {
        final beforeArrival = arrivalDate.subtract(const Duration(days: 1));
        expect(DayCalculator.isBatchActive(arrivalDate, now: beforeArrival), isFalse);
      });

      test('returns false long after cycle ended (e.g. day 100)', () {
        final day100 = arrivalDate.add(const Duration(days: 99));
        expect(DayCalculator.isBatchActive(arrivalDate, now: day100), isFalse);
      });
    });

    group('weekNumber', () {
      test('calculates week 1 for days 1 through 7', () {
        for (var day = 1; day <= 7; day++) {
          expect(DayCalculator.weekNumber(day), equals(1),
              reason: 'Day $day should be week 1');
        }
      });

      test('calculates week 2 for days 8 through 14', () {
        for (var day = 8; day <= 14; day++) {
          expect(DayCalculator.weekNumber(day), equals(2),
              reason: 'Day $day should be week 2');
        }
      });

      test('calculates week 3 for days 15 through 21', () {
        for (var day = 15; day <= 21; day++) {
          expect(DayCalculator.weekNumber(day), equals(3),
              reason: 'Day $day should be week 3');
        }
      });

      test('calculates week 4 for days 22 through 28', () {
        for (var day = 22; day <= 28; day++) {
          expect(DayCalculator.weekNumber(day), equals(4),
              reason: 'Day $day should be week 4');
        }
      });

      test('calculates week 5 for days 29 through 35', () {
        for (var day = 29; day <= 35; day++) {
          expect(DayCalculator.weekNumber(day), equals(5),
              reason: 'Day $day should be week 5');
        }
      });

      test('calculates week 6 for days 36 through 42', () {
        for (var day = 36; day <= 42; day++) {
          expect(DayCalculator.weekNumber(day), equals(6),
              reason: 'Day $day should be week 6');
        }
      });
    });

    group('daysRemaining', () {
      test('returns 41 days remaining on day 1', () {
        final now = arrivalDate;
        expect(DayCalculator.daysRemaining(arrivalDate, now: now), equals(41));
      });

      test('returns 40 days remaining on day 2', () {
        final now = arrivalDate.add(const Duration(days: 1));
        expect(DayCalculator.daysRemaining(arrivalDate, now: now), equals(40));
      });

      test('returns 21 days remaining on day 21', () {
        final now = arrivalDate.add(const Duration(days: 20));
        expect(DayCalculator.daysRemaining(arrivalDate, now: now), equals(21));
      });

      test('returns 1 day remaining on day 41', () {
        final now = arrivalDate.add(const Duration(days: 40));
        expect(DayCalculator.daysRemaining(arrivalDate, now: now), equals(1));
      });

      test('returns 0 days remaining on day 42', () {
        final now = arrivalDate.add(const Duration(days: 41));
        expect(DayCalculator.daysRemaining(arrivalDate, now: now), equals(0));
      });

      test('clamps to 0 when batch is past day 42', () {
        final day43 = arrivalDate.add(const Duration(days: 42));
        final day50 = arrivalDate.add(const Duration(days: 49));
        expect(DayCalculator.daysRemaining(arrivalDate, now: day43), equals(0));
        expect(DayCalculator.daysRemaining(arrivalDate, now: day50), equals(0));
      });

      test('clamps to 42 when date is before arrival', () {
        final beforeArrival = arrivalDate.subtract(const Duration(days: 5));
        expect(
          DayCalculator.daysRemaining(arrivalDate, now: beforeArrival),
          equals(42),
        );
      });
    });
  });
}
