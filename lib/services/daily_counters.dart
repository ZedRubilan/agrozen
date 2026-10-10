import 'package:shared_preferences/shared_preferences.dart';

/// Owns the per-day counters stored in [SharedPreferences].
///
/// **Why this exists:** the diary counters (`today_mortality`, `today_feed`) and
/// the AI quota (`remaining_questions`) are *daily* values. Before this helper
/// they were only ever incremented, never reset, so:
///   - "mortality today" silently became "mortality since install", which made
///     the 1%/day alert fire on cumulative numbers;
///   - "feed today" grew without bound;
///   - the 30-questions-per-day quota became a 30-questions-*ever* quota and the
///     farmer was locked out permanently.
///
/// Every read goes through [ensureToday], which compares the stored stamp
/// against today and rolls the counters over when the day changes.
class DailyCounters {
  DailyCounters._();

  static const String _dateKey = 'counters_date';
  static const String _mortalityKey = 'today_mortality';
  static const String _feedKey = 'today_feed';
  static const String _questionsKey = 'remaining_questions';

  /// Resets the daily counters if the stored day is not today.
  ///
  /// Safe to call on every screen load. Returns the prefs instance so callers
  /// can continue reading values in the same tick.
  static Future<SharedPreferences> ensureToday(
    SharedPreferences prefs, {
    int maxDailyQuestions = 30,
  }) async {
    final today = _todayStamp();
    final stored = prefs.getString(_dateKey);

    if (stored == today) return prefs;

    await prefs.setString(_dateKey, today);
    await prefs.setInt(_mortalityKey, 0);
    await prefs.setDouble(_feedKey, 0.0);
    await prefs.setInt(_questionsKey, maxDailyQuestions);
    return prefs;
  }

  /// Convenience wrapper: fetches prefs and rolls the day over in one call.
  static Future<SharedPreferences> rolled({int maxDailyQuestions = 30}) async {
    final prefs = await SharedPreferences.getInstance();
    return ensureToday(prefs, maxDailyQuestions: maxDailyQuestions);
  }

  static int getMortality(SharedPreferences prefs) =>
      prefs.getInt(_mortalityKey) ?? 0;

  static Future<void> addMortality(SharedPreferences prefs, int deaths) async {
    await prefs.setInt(_mortalityKey, getMortality(prefs) + deaths);
  }

  static double getFeed(SharedPreferences prefs) =>
      prefs.getDouble(_feedKey) ?? 0.0;

  static Future<void> addFeed(SharedPreferences prefs, double kg) async {
    await prefs.setDouble(_feedKey, getFeed(prefs) + kg);
  }

  static int getRemainingQuestions(
    SharedPreferences prefs, {
    int maxDailyQuestions = 30,
  }) =>
      prefs.getInt(_questionsKey) ?? maxDailyQuestions;

  static Future<void> setRemainingQuestions(
    SharedPreferences prefs,
    int remaining,
  ) async {
    await prefs.setInt(_questionsKey, remaining < 0 ? 0 : remaining);
  }

  /// Clears every daily counter and the day stamp. Used when the farmer starts
  /// a brand new batch.
  static Future<void> resetAll(SharedPreferences prefs) async {
    await prefs.remove(_dateKey);
    await prefs.remove(_mortalityKey);
    await prefs.remove(_feedKey);
    await prefs.remove(_questionsKey);
    await prefs.remove('last_weight');
  }

  /// Today's stamp in the same format used for persistence.
  /// Exposed so tests can seed counters for "today" without duplicating the
  /// format logic.
  static String todayStamp() => _todayStamp();

  /// `yyyy-mm-dd` in local time — matches how a farmer thinks about "today".
  static String _todayStamp() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}
