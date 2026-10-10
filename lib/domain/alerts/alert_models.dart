import 'package:equatable/equatable.dart';

enum AlertType { highMortality, lowWeight, highTemperature }
enum AlertSeverity { warning, critical }

class AlertResult extends Equatable {
  final AlertType type;
  final AlertSeverity severity;
  final double actualValue;
  final double threshold;
  final String? messageRu;
  final String? messageUz;
  final String? messageEn;

  const AlertResult({
    required this.type,
    required this.severity,
    required this.actualValue,
    required this.threshold,
    this.messageRu,
    this.messageUz,
    this.messageEn,
  });

  @override
  List<Object?> get props => [type, severity, actualValue, threshold];
}

class NormsData {
  final double mortalityThresholdPercent;
  final double cumulativeMortalityThresholdPercent;
  final Map<int, double> weeklyWeightTargets;

  /// Exact per-day weight targets parsed from `knowledge/norms.json`
  /// (`daily_norms`, days 1..42). Preferred over [weeklyWeightTargets].
  final Map<int, double> dailyWeightTargets;

  /// Exact per-day temperature targets in Celsius (days 1..42).
  final Map<int, double> dailyTemperatureTargets;

  final double weightDeviationPercent;
  final double tempDeviationCelsius;
  final Map<int, double> dailyFeedPerBird;
  final Map<int, double> temperatureTargets;

  const NormsData({
    required this.mortalityThresholdPercent,
    required this.weeklyWeightTargets,
    required this.weightDeviationPercent,
    required this.dailyFeedPerBird,
    required this.temperatureTargets,
    Map<int, double>? dailyWeightTargets,
    Map<int, double>? dailyTemperatureTargets,
    this.cumulativeMortalityThresholdPercent = 4.0,
    this.tempDeviationCelsius = 2.0,
  })  : dailyWeightTargets = dailyWeightTargets ?? const {},
        dailyTemperatureTargets = dailyTemperatureTargets ?? const {};

  /// Parses the shipped `knowledge/norms.json` schema:
  /// ```
  /// {
  ///   "breed": "...",
  ///   "critical_thresholds": { "daily_mortality_alert_percent", ... },
  ///   "weekly_norms": [ { "week", "target_weight_g", ... } ],
  ///   "daily_norms":  { "1": { "weight_g", "feed_g", "temp_c" } }
  /// }
  /// ```
  ///
  /// Never throws on missing sections — falls back to the legacy flat schema
  /// and finally to built-in Ross-308 / Cobb-500 defaults.
  factory NormsData.fromJson(Map<String, dynamic> json) {
    final critical = _asMap(json['critical_thresholds']);
    final alertThresholds = _asMap(json['alert_thresholds']);
    final legacyMortality = _asMap(json['mortality']);

    final mortalityThreshold =
        _toDouble(critical['daily_mortality_alert_percent']) ??
            _toDouble(alertThresholds['daily_mortality_percent']) ??
            _toDouble(legacyMortality['daily_threshold_percent']) ??
            1.0;

    final cumulativeMortalityThreshold =
        _toDouble(critical['cumulative_mortality_warning_percent']) ??
            _toDouble(alertThresholds['cumulative_mortality_percent']) ??
            4.0;

    final legacyWeight = _asMap(json['weight']);
    final weightDeviation =
        _toDouble(critical['weight_deficit_alert_percent']) ??
            _toDouble(alertThresholds['weekly_weight_deviation_percent']) ??
            _toDouble(legacyWeight['deviation_percent']) ??
            15.0;

    final tempDeviation =
        _toDouble(critical['temp_deviation_celsius']) ??
            _toDouble(alertThresholds['temp_deviation_celsius']) ??
            2.0;

    // --- Shipped schema: weekly_norms (list) and/or daily_norms (map) ---
    final weeklyRaw = json['weekly_norms'];
    final dailyRaw = json['daily_norms'];

    if (weeklyRaw is List || dailyRaw is Map) {
      final weekly = <int, double>{};
      final weeklyFeed = <int, double>{};
      final weeklyTemp = <int, double>{};
      if (weeklyRaw is List) {
        for (final entry in weeklyRaw) {
          if (entry is! Map) continue;
          final week = _toInt(entry['week']);
          if (week == null) continue;
          final dayKey = week * 7;
          final tw = _toDouble(entry['target_weight_g']);
          if (tw != null) weekly[dayKey] = tw;
          final df = _toDouble(entry['daily_feed_g']);
          if (df != null) weeklyFeed[dayKey] = df;
          final tc = _toDouble(entry['temperature_c']);
          if (tc != null) weeklyTemp[dayKey] = tc;
        }
      }

      final dailyWeight = <int, double>{};
      final dailyFeed = <int, double>{};
      final dailyTemp = <int, double>{};
      if (dailyRaw is Map) {
        for (final entry in dailyRaw.entries) {
          final day = int.tryParse(entry.key.toString());
          if (day == null || entry.value is! Map) continue;
          final m = entry.value as Map;
          final w = _toDouble(m['weight_g']);
          final f = _toDouble(m['feed_g']);
          final t = _toDouble(m['temp_c']);
          if (w != null) dailyWeight[day] = w;
          if (f != null) dailyFeed[day] = f;
          if (t != null) dailyTemp[day] = t;
        }
      }

      return NormsData(
        mortalityThresholdPercent: mortalityThreshold,
        cumulativeMortalityThresholdPercent: cumulativeMortalityThreshold,
        weeklyWeightTargets: weekly,
        dailyWeightTargets: dailyWeight,
        dailyTemperatureTargets: dailyTemp,
        weightDeviationPercent: weightDeviation,
        tempDeviationCelsius: tempDeviation,
        dailyFeedPerBird: dailyFeed.isNotEmpty ? dailyFeed : weeklyFeed,
        temperatureTargets: dailyTemp.isNotEmpty ? dailyTemp : weeklyTemp,
      );
    }

    // --- Legacy flat schema & fallback keys (kept for backwards compatibility) ---
    final feed = _asMap(json['feed']);
    final temp = _asMap(json['temperature']);

    final weeklyWeights = _numMap(legacyWeight['weekly_targets_grams']);
    final flatWeeklyWeights = _numMap(json['weekly_weight_targets']);

    final feedMap = _numMap(feed['daily_grams_per_bird']);
    final flatFeedMap = _numMap(json['daily_feed_per_bird']);

    final tempMap = _numMap(temp['targets_celsius']);
    final flatTempMap = _numMap(json['temperature_targets']);

    return NormsData(
      mortalityThresholdPercent: mortalityThreshold,
      cumulativeMortalityThresholdPercent: cumulativeMortalityThreshold,
      weeklyWeightTargets:
          weeklyWeights.isNotEmpty ? weeklyWeights : flatWeeklyWeights,
      weightDeviationPercent: weightDeviation,
      tempDeviationCelsius: tempDeviation,
      dailyFeedPerBird: feedMap.isNotEmpty ? feedMap : flatFeedMap,
      temperatureTargets: tempMap.isNotEmpty ? tempMap : flatTempMap,
    );
  }

  /// Get the target weight for a given day.
  /// Prefers the exact daily norm; falls back to the closest daily or weekly
  /// checkpoint at or before [day].
  double? weightTargetForDay(int day) {
    final exact = dailyWeightTargets[day];
    if (exact != null && exact > 0) return exact;

    final dailyClosest = _closestCheckpoint(dailyWeightTargets, day);
    final weeklyClosest = _closestCheckpoint(weeklyWeightTargets, day);

    if (dailyClosest != null && weeklyClosest != null) {
      return dailyClosest >= weeklyClosest
          ? dailyWeightTargets[dailyClosest]
          : weeklyWeightTargets[weeklyClosest];
    }
    if (dailyClosest != null) return dailyWeightTargets[dailyClosest];
    if (weeklyClosest != null) return weeklyWeightTargets[weeklyClosest];
    return null;
  }

  /// Get the target temperature for a given day, or null if unknown.
  double? temperatureTargetForDay(int day) {
    final exact = dailyTemperatureTargets[day];
    if (exact != null && exact > 0) return exact;

    final dailyClosest = _closestCheckpoint(dailyTemperatureTargets, day);
    final targetClosest = _closestCheckpoint(temperatureTargets, day);

    if (dailyClosest != null && targetClosest != null) {
      return dailyClosest >= targetClosest
          ? dailyTemperatureTargets[dailyClosest]
          : temperatureTargets[targetClosest];
    }
    if (dailyClosest != null) return dailyTemperatureTargets[dailyClosest];
    if (targetClosest != null) return temperatureTargets[targetClosest];
    return null;
  }

  /// Get the target daily feed per bird (in grams) for a given day, or null if unknown.
  double? feedTargetForDay(int day) {
    final exact = dailyFeedPerBird[day];
    if (exact != null && exact > 0) return exact;

    final closest = _closestCheckpoint(dailyFeedPerBird, day);
    return closest != null ? dailyFeedPerBird[closest] : null;
  }

  static int? _closestCheckpoint(Map<int, double> map, int day) {
    if (map.isEmpty) return null;
    final checkpoints = map.keys.toList()..sort();
    int? closest;
    for (final cp in checkpoints) {
      final val = map[cp];
      if (cp <= day && val != null && val > 0) {
        closest = cp;
      }
    }
    return closest;
  }

  static Map<String, dynamic> _asMap(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static Map<int, double> _numMap(Object? value) {
    if (value is! Map) return <int, double>{};
    final out = <int, double>{};
    for (final entry in value.entries) {
      final key = int.tryParse(entry.key.toString());
      final num = _toDouble(entry.value);
      if (key != null && num != null) out[key] = num;
    }
    return out;
  }

  static double? _toDouble(Object? value) => value is num ? value.toDouble() : null;
  static int? _toInt(Object? value) => value is num ? value.toInt() : null;
}
