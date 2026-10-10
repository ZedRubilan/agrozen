import 'package:agrozen/services/daily_counters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression tests for the daily counter rollover.
///
/// Before `DailyCounters` existed, `today_mortality`, `today_feed` and
/// `remaining_questions` were only ever incremented. That made:
///   - the 1%/day mortality alert fire on cumulative deaths, and
///   - the 30-questions-per-day AI quota a permanent lifetime lockout.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyCounters', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('todayStamp is a yyyy-mm-dd local date', () {
      final now = DateTime.now();
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      expect(DailyCounters.todayStamp(), '${now.year}-$month-$day');
    });

    test('first run initialises all counters to today', () async {
      final prefs = await DailyCounters.rolled();

      expect(prefs.getString('counters_date'), DailyCounters.todayStamp());
      expect(DailyCounters.getMortality(prefs), 0);
      expect(DailyCounters.getFeed(prefs), 0.0);
      expect(DailyCounters.getRemainingQuestions(prefs), 30);
    });

    test('counters accumulate within the same day', () async {
      var prefs = await DailyCounters.rolled();

      await DailyCounters.addMortality(prefs, 3);
      await DailyCounters.addMortality(prefs, 2);
      await DailyCounters.addFeed(prefs, 12.5);
      await DailyCounters.setRemainingQuestions(prefs, 27);

      prefs = await DailyCounters.rolled();

      expect(DailyCounters.getMortality(prefs), 5);
      expect(DailyCounters.getFeed(prefs), 12.5);
      expect(DailyCounters.getRemainingQuestions(prefs), 27);
    });

    test("yesterday's counters are rolled over, not carried forward", () async {
      SharedPreferences.setMockInitialValues({
        'counters_date': '2001-01-01',
        'today_mortality': 40,
        'today_feed': 900.0,
        'remaining_questions': 0,
      });

      final prefs = await DailyCounters.rolled();

      expect(DailyCounters.getMortality(prefs), 0);
      expect(DailyCounters.getFeed(prefs), 0.0);
      expect(DailyCounters.getRemainingQuestions(prefs), 30);
    });

    test('the AI quota is restored the next day after being exhausted',
        () async {
      SharedPreferences.setMockInitialValues({
        'counters_date': '2001-01-01',
        'remaining_questions': 0,
      });

      final prefs = await DailyCounters.rolled();
      expect(DailyCounters.getRemainingQuestions(prefs), 30);
    });

    test('a custom daily question limit is respected on rollover', () async {
      SharedPreferences.setMockInitialValues({
        'counters_date': '2001-01-01',
      });

      final prefs = await DailyCounters.rolled(maxDailyQuestions: 10);
      expect(DailyCounters.getRemainingQuestions(prefs, maxDailyQuestions: 10), 10);
    });

    test('remaining questions never goes negative', () async {
      final prefs = await DailyCounters.rolled();

      await DailyCounters.setRemainingQuestions(prefs, -5);
      expect(DailyCounters.getRemainingQuestions(prefs), 0);
    });

    test('resetAll clears counters, last_weight, and the day stamp', () async {
      var prefs = await DailyCounters.rolled();
      await DailyCounters.addMortality(prefs, 7);
      await DailyCounters.addFeed(prefs, 20);
      await prefs.setDouble('last_weight', 480.0);

      await DailyCounters.resetAll(prefs);

      expect(prefs.getString('counters_date'), isNull);
      expect(prefs.getDouble('last_weight'), isNull);
      // A fresh read re-initialises to zero for today.
      prefs = await DailyCounters.rolled();
      expect(DailyCounters.getMortality(prefs), 0);
      expect(DailyCounters.getFeed(prefs), 0.0);
    });

    test('ensureToday is idempotent within the same day', () async {
      var prefs = await DailyCounters.rolled();
      await DailyCounters.addMortality(prefs, 4);

      prefs = await DailyCounters.rolled();
      prefs = await DailyCounters.rolled();

      expect(DailyCounters.getMortality(prefs), 4);
    });
  });
}
