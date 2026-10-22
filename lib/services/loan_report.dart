import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/broiler/broiler_grower_library.dart';
import 'farm_store.dart';
import 'lesson_progress.dart';

enum LoanRisk { low, medium, high }

/// One line of the score: what was checked and how many points it earned.
class ReportFactor {
  final String key; // survival · diary · weight · training
  final int points;
  final int maxPoints;

  const ReportFactor(this.key, this.points, this.maxPoints);

  double get share => maxPoints > 0 ? points / maxPoints : 0;
}

/// Deaths in one week of the batch, as a share of the chicks placed.
class WeekMortality {
  final int week;
  final int deaths;
  final double pct;

  const WeekMortality(this.week, this.deaths, this.pct);
}

/// The batch report a farmer can share with their bank or insurer.
///
/// Built only from the farmer's own diary and the Ross-308 / Cobb-500 norms;
/// the score is plain arithmetic, not AI, so the bank can check every point.
class LoanReport {
  final FarmSnapshot farm;
  final int lessonsDone;
  final double cumulativeMortalityLimitPct;

  /// Distinct days of this batch with at least one diary entry.
  final int daysRecorded;
  final List<WeekMortality> weeks;
  final List<ReportFactor> factors;

  /// Feed per kg of live weight, only when feed was logged every day.
  final double? fcr;

  const LoanReport._({
    required this.farm,
    required this.lessonsDone,
    required this.cumulativeMortalityLimitPct,
    required this.daysRecorded,
    required this.weeks,
    required this.factors,
    required this.fcr,
  });

  static const int maxScore = 100;

  int get score => factors.fold(0, (sum, f) => sum + f.points);

  LoanRisk get risk => score >= 75
      ? LoanRisk.low
      : (score >= 50 ? LoanRisk.medium : LoanRisk.high);

  double get diaryCoverage =>
      farm.batchDay > 0 ? math.min(1.0, daysRecorded / farm.batchDay) : 0.0;

  bool get certified => lessonsDone >= LessonProgress.totalLessons;

  /// Last sample weight as a share of its day's Ross-308 target.
  double? get weightVsTarget => _weightRatio(farm);

  static double? _weightRatio(FarmSnapshot farm) =>
      farm.hasWeight && farm.targetForLastWeight > 0
      ? farm.lastWeightG / farm.targetForLastWeight
      : null;

  BroilerDaySpec get spec => farm.spec;

  static LoanReport build({
    required FarmSnapshot farm,
    required int lessonsDone,
    double cumulativeMortalityLimitPct = 4.0,
  }) {
    final batchDays = farm.history
        .where((r) => r.day >= 1 && r.day <= farm.batchDay)
        .toList();
    final daysRecorded = batchDays.map((r) => r.date).toSet().length;

    final weeks = <WeekMortality>[];
    for (var w = 1; w <= (farm.batchDay + 6) ~/ 7; w++) {
      final deaths = batchDays
          .where((r) => (r.day + 6) ~/ 7 == w)
          .fold(0, (sum, r) => sum + r.deaths);
      final pct = farm.initialCount > 0
          ? deaths * 100.0 / farm.initialCount
          : 0.0;
      weeks.add(WeekMortality(w, deaths, pct));
    }

    final feedDays = batchDays.where((r) => r.feedKg > 0).length;
    double? fcr;
    if (farm.hasWeight && feedDays >= farm.batchDay && farm.currentCount > 0) {
      final liveKg = farm.currentCount * farm.lastWeightG / 1000.0;
      final value = farm.totalFeedLoggedKg / liveKg;
      if (BroilerGrowerLibrary.isPlausibleFcr(day: farm.batchDay, fcr: value)) {
        fcr = value;
      }
    }

    final lessons = lessonsDone.clamp(0, LessonProgress.totalLessons);
    final coverage = farm.batchDay > 0
        ? math.min(1.0, daysRecorded / farm.batchDay)
        : 0.0;
    final weightRatio = _weightRatio(farm);

    return LoanReport._(
      farm: farm,
      lessonsDone: lessons,
      cumulativeMortalityLimitPct: cumulativeMortalityLimitPct,
      daysRecorded: daysRecorded,
      weeks: weeks,
      factors: _score(
        mortalityPct: farm.cumulativeMortalityPct,
        mortalityLimitPct: cumulativeMortalityLimitPct,
        diaryCoverage: coverage,
        weightRatio: weightRatio,
        lessonsDone: lessons,
      ),
      fcr: fcr,
    );
  }

  /// 40 survival · 25 diary · 20 weight · 15 training = 100.
  static List<ReportFactor> _score({
    required double mortalityPct,
    required double mortalityLimitPct,
    required double diaryCoverage,
    required double? weightRatio,
    required int lessonsDone,
  }) {
    final limit = mortalityLimitPct;
    final survival = mortalityPct <= limit / 2
        ? 40
        : mortalityPct <= limit
        ? 30
        : mortalityPct <= limit * 2
        ? 15
        : 0;

    final diary = (25 * diaryCoverage).round();

    final ratio = weightRatio;
    final weight = ratio == null
        ? 5 // not weighed yet: no evidence either way
        : ratio >= 0.95
        ? 20
        : ratio >= 0.85
        ? 10
        : 0;

    final training = (15 * lessonsDone / LessonProgress.totalLessons).round();

    return [
      ReportFactor('survival', survival, 40),
      ReportFactor('diary', diary, 25),
      ReportFactor('weight', weight, 20),
      ReportFactor('training', training, 15),
    ];
  }
}

/// The farmer's permission to share the report. Nothing leaves the phone
/// until they give it, and they can take it back at any time.
class ReportConsent {
  ReportConsent._();

  static const String _key = 'bank_report_consent_at';

  static Future<DateTime?> givenAt() async {
    final prefs = await SharedPreferences.getInstance();
    return DateTime.tryParse(prefs.getString(_key) ?? '');
  }

  static Future<void> give() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, DateTime.now().toIso8601String());
  }

  static Future<void> revoke() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
