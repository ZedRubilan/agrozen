import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../core/localization/app_strings.dart';
import '../data/repositories/knowledge_repository.dart';
import '../domain/alerts/alert_engine.dart';
import '../domain/alerts/alert_models.dart';
import '../domain/broiler/broiler_grower_library.dart';
import '../domain/scheduler/day_calculator.dart';
import 'daily_counters.dart';
import 'location_service.dart';

/// What happened on one calendar day of the batch.
class DayRecord {
  final String date; // yyyy-mm-dd
  final int day; // batch day 1..42
  final int deaths;
  final double feedKg;
  final double? weightG;

  const DayRecord({
    required this.date,
    required this.day,
    this.deaths = 0,
    this.feedKg = 0,
    this.weightG,
  });

  bool get isEmpty => deaths == 0 && feedKg == 0 && weightG == null;

  DayRecord copyWith({int? deaths, double? feedKg, double? weightG}) {
    return DayRecord(
      date: date,
      day: day,
      deaths: deaths ?? this.deaths,
      feedKg: feedKg ?? this.feedKg,
      weightG: weightG ?? this.weightG,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'day': day,
        'deaths': deaths,
        'feed_kg': feedKg,
        if (weightG != null) 'weight_g': weightG,
      };

  factory DayRecord.fromJson(Map<String, dynamic> json) => DayRecord(
        date: json['date'] as String? ?? '',
        day: (json['day'] as num?)?.toInt() ?? 1,
        deaths: (json['deaths'] as num?)?.toInt() ?? 0,
        feedKg: (json['feed_kg'] as num?)?.toDouble() ?? 0,
        weightG: (json['weight_g'] as num?)?.toDouble(),
      );
}

/// Everything a screen needs to know about the farm right now.
///
/// Built only by [FarmStore.load], so every screen agrees on the batch day,
/// flock size, district and targets.
class FarmSnapshot {
  final String lang;
  final String farmerName;
  final String district;
  final String? locality;
  final int initialCount;
  final int currentCount;
  final int isolatedCount;
  final DateTime arrivalDate;

  /// Unclamped batch day (can exceed 42 when the batch is over).
  final int rawBatchDay;
  final int todayDeaths;
  final double todayFeedKg;
  final double lastWeightG;

  /// Batch day on which [lastWeightG] was measured.
  final int? lastWeightDay;
  final bool locationPromptResolved;

  /// Newest first.
  final List<DayRecord> history;

  const FarmSnapshot({
    required this.lang,
    required this.farmerName,
    required this.district,
    required this.locality,
    required this.initialCount,
    required this.currentCount,
    required this.isolatedCount,
    required this.arrivalDate,
    required this.rawBatchDay,
    required this.todayDeaths,
    required this.todayFeedKg,
    required this.lastWeightG,
    required this.lastWeightDay,
    required this.locationPromptResolved,
    required this.history,
  });

  /// Batch day clamped to the 1..42 growing cycle.
  int get batchDay => rawBatchDay.clamp(1, AppConstants.broilerCycleDays);

  bool get batchFinished => rawBatchDay > AppConstants.broilerCycleDays;

  int get daysLeft => math.max(0, AppConstants.broilerCycleDays - batchDay);

  double get cycleProgress => batchDay / AppConstants.broilerCycleDays;

  BroilerDaySpec get spec => BroilerGrowerLibrary.specForDay(batchDay);

  /// Today's feed / water / space requirements for the live flock.
  FlockDailyRequirements get requirements =>
      BroilerGrowerLibrary.calculateFlockRequirements(
        day: batchDay,
        birdCount: currentCount,
      );

  int get totalDeaths => math.max(0, initialCount - currentCount);

  double get survivalPct =>
      initialCount > 0 ? (currentCount * 100.0 / initialCount).clamp(0, 100) : 100;

  double get cumulativeMortalityPct =>
      initialCount > 0 ? totalDeaths * 100.0 / initialCount : 0;

  /// Total feed the farmer has logged in this batch.
  double get totalFeedLoggedKg =>
      history.fold(0.0, (sum, r) => sum + r.feedKg);

  bool get hasWeight => lastWeightG > 0;

  /// Today's diary record, if anything was logged today.
  DayRecord? get todayRecord {
    final stamp = DailyCounters.todayStamp();
    for (final r in history) {
      if (r.date == stamp) return r;
    }
    return null;
  }

  /// Target weight for the day the last sample was weighed.
  double get targetForLastWeight =>
      BroilerGrowerLibrary.specForDay(lastWeightDay ?? batchDay).targetWeightG;

  String get locationLabel => LocationService.formatLocationLabel(
        district: district,
        locality: locality,
        lang: lang,
      );

  String phaseName() => phaseNameFor(batchDay, lang);

  static String phaseNameFor(int day, String lang) {
    final spec = BroilerGrowerLibrary.specForDay(day);
    switch (spec.phaseKey) {
      case 'pre_starter':
      case 'starter':
        return AppStrings.tr(lang: lang, uz: 'Start', ru: 'Старт', en: 'Starter');
      case 'grower':
        return AppStrings.tr(lang: lang, uz: "O'sish", ru: 'Рост', en: 'Grower');
      default:
        return AppStrings.tr(lang: lang, uz: 'Finish', ru: 'Финиш', en: 'Finisher');
    }
  }
}

/// The single place that reads and writes the farmer's flock data.
class FarmStore {
  FarmStore._();

  static const String historyKey = 'flock_history_v1';
  static const String lastWeightDayKey = 'last_weight_day';

  /// Bumped after every change to farm data, so open screens can reload.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static void notifyChanged() => changes.value++;

  static Future<FarmSnapshot> load({String? localeFallback}) async {
    final prefs = await DailyCounters.rolled(
      maxDailyQuestions: AppConstants.maxDailyQuestions,
    );
    await _repairStaleIpLocation(prefs);

    final initial = prefs.getInt('initial_count') ?? AppConstants.defaultFlockSize;
    final current = (prefs.getInt('current_count') ?? initial).clamp(0, 1 << 30);
    final arrival = DateTime.tryParse(prefs.getString('arrival_date') ?? '') ??
        DateTime.now();

    return FarmSnapshot(
      lang: prefs.getString('app_language') ?? localeFallback ?? 'uz',
      farmerName: prefs.getString('farmer_name') ?? 'Fermer',
      district: prefs.getString('farmer_district') ?? AppConstants.defaultDistrict,
      locality: prefs.getString('farmer_locality'),
      initialCount: initial,
      currentCount: current,
      isolatedCount: DailyCounters.getIsolatedCount(prefs).clamp(0, current),
      arrivalDate: arrival,
      rawBatchDay: math.max(1, DayCalculator.calculateBatchDay(arrival)),
      todayDeaths: DailyCounters.getMortality(prefs),
      todayFeedKg: DailyCounters.getFeed(prefs),
      lastWeightG: prefs.getDouble('last_weight') ?? 0,
      lastWeightDay: prefs.getInt(lastWeightDayKey),
      locationPromptResolved:
          prefs.getBool('location_prompt_resolved') ?? false,
      history: readHistory(prefs),
    );
  }

  /// A one-off fix for installs where an IP lookup wrongly auto-detected the
  /// Tashkent ISP gateway. A district the farmer picked by hand is never
  /// touched.
  static Future<void> _repairStaleIpLocation(SharedPreferences prefs) async {
    if (prefs.getBool('chartak_geo_fix_v1') ?? false) return;
    final autoDetected = prefs.getBool('location_auto_detected') ?? false;
    if (autoDetected && prefs.getString('farmer_district') == 'Toshkent') {
      await LocationService.saveManualLocality(LocationService.chartakLocality);
    }
    await prefs.setBool('chartak_geo_fix_v1', true);
  }

  // --- History -------------------------------------------------------------

  static List<DayRecord> readHistory(SharedPreferences prefs) {
    final raw = prefs.getString(historyKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => DayRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((r) => !r.isEmpty)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _updateToday(
    SharedPreferences prefs,
    DayRecord Function(DayRecord today) update,
  ) async {
    final stamp = DailyCounters.todayStamp();
    final arrival = DateTime.tryParse(prefs.getString('arrival_date') ?? '');
    final day = arrival == null
        ? 1
        : DayCalculator.calculateBatchDay(arrival)
            .clamp(1, AppConstants.broilerCycleDays);

    final history = readHistory(prefs);
    final index = history.indexWhere((r) => r.date == stamp);
    final current = index >= 0 ? history[index] : DayRecord(date: stamp, day: day);
    final updated = update(current);
    if (index >= 0) {
      history[index] = updated;
    } else {
      history.add(updated);
    }
    await prefs.setString(
      historyKey,
      jsonEncode(history.map((r) => r.toJson()).toList()),
    );
  }

  // --- Mutations -----------------------------------------------------------

  /// Records [deaths] lost birds today. Returns the alerts this triggers.
  static Future<List<AlertResult>> logDeaths(int deaths) async {
    if (deaths <= 0) return const [];
    final prefs = await DailyCounters.rolled(
      maxDailyQuestions: AppConstants.maxDailyQuestions,
    );
    final initial = prefs.getInt('initial_count') ?? AppConstants.defaultFlockSize;
    final before = prefs.getInt('current_count') ?? initial;
    final applied = math.min(deaths, before);
    if (applied <= 0) return const [];

    final after = before - applied;
    await DailyCounters.addMortality(prefs, applied);
    await prefs.setInt('current_count', after);
    final isolated = DailyCounters.getIsolatedCount(prefs);
    if (isolated > after) {
      await DailyCounters.setIsolatedCount(prefs, after, maxCount: after);
    }
    await _updateToday(prefs, (r) => r.copyWith(deaths: r.deaths + applied));
    notifyChanged();

    final snapshot = await load();
    final alerts = await evaluateAlerts(snapshot);
    return alerts.where((a) => a.type == AlertType.highMortality).toList();
  }

  static Future<void> logFeed(double kg) async {
    if (kg <= 0) return;
    final prefs = await DailyCounters.rolled(
      maxDailyQuestions: AppConstants.maxDailyQuestions,
    );
    await DailyCounters.addFeed(prefs, kg);
    await _updateToday(prefs, (r) => r.copyWith(feedKg: r.feedKg + kg));
    notifyChanged();
  }

  /// Records the average sample weight. Returns a low-weight alert if any.
  static Future<AlertResult?> logWeight(double grams) async {
    if (grams <= 0) return null;
    final prefs = await DailyCounters.rolled(
      maxDailyQuestions: AppConstants.maxDailyQuestions,
    );
    final arrival = DateTime.tryParse(prefs.getString('arrival_date') ?? '');
    final day = arrival == null
        ? 1
        : DayCalculator.calculateBatchDay(arrival)
            .clamp(1, AppConstants.broilerCycleDays);
    await prefs.setDouble('last_weight', grams);
    await prefs.setInt(lastWeightDayKey, day);
    await _updateToday(prefs, (r) => r.copyWith(weightG: grams));
    notifyChanged();

    final norms = await KnowledgeRepository().getParsedNorms();
    return AlertEngine(norms).checkWeight(weightGrams: grams, batchDay: day);
  }

  static Future<void> setIsolated(int count) async {
    final prefs = await DailyCounters.rolled(
      maxDailyQuestions: AppConstants.maxDailyQuestions,
    );
    final current = prefs.getInt('current_count') ?? 0;
    await DailyCounters.setIsolatedCount(prefs, count, maxCount: current);
    notifyChanged();
  }

  /// Wipes the current batch so the farmer can set up a new one.
  static Future<void> resetBatch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('arrival_date');
    await prefs.remove('last_weight');
    await prefs.remove(lastWeightDayKey);
    await prefs.remove(historyKey);
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith(TaskChecklist.keyPrefix)) await prefs.remove(key);
    }
    await DailyCounters.resetAll(prefs);
    notifyChanged();
  }

  // --- Alerts --------------------------------------------------------------

  /// Runs the vet-verified alert rules against the snapshot.
  static Future<List<AlertResult>> evaluateAlerts(FarmSnapshot s) async {
    final NormsData norms;
    try {
      norms = await KnowledgeRepository().getParsedNorms();
    } catch (_) {
      return const [];
    }
    final engine = AlertEngine(norms);
    final alerts = <AlertResult>[];

    final daily = engine.checkMortality(
      deaths: s.todayDeaths,
      // Rate is measured against the flock at the start of the day.
      currentCount: s.currentCount + s.todayDeaths,
    );
    if (daily != null) alerts.add(daily);

    final cumulative = engine.checkCumulativeMortality(
      totalDeaths: s.totalDeaths,
      initialCount: s.initialCount,
      batchDay: s.batchDay,
    );
    if (cumulative != null && daily == null) alerts.add(cumulative);

    if (s.hasWeight) {
      final weight = engine.checkWeight(
        weightGrams: s.lastWeightG,
        batchDay: s.lastWeightDay ?? s.batchDay,
      );
      if (weight != null) alerts.add(weight);
    }
    return alerts;
  }

  /// The district vet, if the directory has one.
  static Future<Map<String, dynamic>?> vetFor(String district) async {
    try {
      final vets = await KnowledgeRepository().getVetByDistrict(district);
      return vets.isNotEmpty ? vets.first : null;
    } catch (_) {
      return null;
    }
  }
}

/// Which of today's plan tasks the farmer has ticked off.
class TaskChecklist {
  TaskChecklist._();

  static const String keyPrefix = 'plan_tasks_done_';

  static String _key(int day) => '$keyPrefix$day';

  static Future<Set<int>> load(int day) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key(day)) ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  static Future<void> save(int day, Set<int> done) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key(day),
      done.map((e) => e.toString()).toList(),
    );
  }
}
