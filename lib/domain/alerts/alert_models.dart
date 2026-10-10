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
  final Map<int, double> weeklyWeightTargets;

  /// Exact per-day weight targets parsed from `knowledge/norms.json`
  /// (`daily_norms`, days 1..42). Preferred over [weeklyWeightTargets].
  final Map<int, double> dailyWeightTargets;

  /// Exact per-day temperature targets in Celsius (days 1..42).
  final Map<int, double> dailyTemperatureTargets;

  final double weightDeviationPercent;
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
    // Thresholds are read independently of the norm tables so that a partially
    // edited norms.json still respects whatever the vet did fill in.
    final critical = _asMap(json['critical_thresholds']);
    final legacyMortality = _asMap(json['mortality']);
    final mortalityThreshold = _toDouble(critical['daily_mortality_alert_percent']) ??
        _toDouble(legacyMortality['daily_threshold_percent']) ??
        1.0;

    final legacyWeight = _asMap(json['weight']);
    final weightDeviation = _toDouble(critical['weight_deficit_alert_percent']) ??
        _toDouble(legacyWeight['deviation_percent']) ??
        15.0;

    // --- Shipped schema: weekly_norms (list) + daily_norms (map) ---
    final weeklyRaw = json['weekly_norms'];
    final dailyRaw = json['daily_norms'];

    if (weeklyRaw is List && dailyRaw is Map) {
      final weekly = <int, double>{};
      for (final entry in weeklyRaw) {
        if (entry is! Map) continue;
        final week = _toInt(entry['week']);
        if (week == null) continue;
        weekly[week * 7] = _toDouble(entry['target_weight_g']) ?? 0;
      }

      final dailyWeight = <int, double>{};
      final dailyFeed = <int, double>{};
      final dailyTemp = <int, double>{};
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

      return NormsData(
        mortalityThresholdPercent: mortalityThreshold,
        weeklyWeightTargets: weekly,
        dailyWeightTargets: dailyWeight,
        dailyTemperatureTargets: dailyTemp,
        weightDeviationPercent: weightDeviation,
        dailyFeedPerBird: dailyFeed,
        temperatureTargets: dailyTemp,
      );
    }

    // --- Legacy flat schema (kept for backwards compatibility) ---
    final feed = _asMap(json['feed']);
    final temp = _asMap(json['temperature']);

    return NormsData(
      mortalityThresholdPercent: mortalityThreshold,
      weeklyWeightTargets: _numMap(legacyWeight['weekly_targets_grams']),
      weightDeviationPercent: weightDeviation,
      dailyFeedPerBird: _numMap(feed['daily_grams_per_bird']),
      temperatureTargets: _numMap(temp['targets_celsius']),
    );
  }

  /// Get the target weight for a given day.
  /// Prefers the exact daily norm; falls back to the closest weekly checkpoint
  /// at or before [day].
  double? weightTargetForDay(int day) {
    final exact = dailyWeightTargets[day];
    if (exact != null && exact > 0) return exact;

    final checkpoints = weeklyWeightTargets.keys.toList()..sort();
    int? closest;
    for (final cp in checkpoints) {
      if (cp <= day) closest = cp;
    }
    return closest != null ? weeklyWeightTargets[closest] : null;
  }

  /// Get the target temperature for a given day, or null if unknown.
  double? temperatureTargetForDay(int day) {
    final exact = dailyTemperatureTargets[day];
    if (exact != null && exact > 0) return exact;

    final checkpoints = temperatureTargets.keys.toList()..sort();
    int? closest;
    for (final cp in checkpoints) {
      if (cp <= day) closest = cp;
    }
    return closest != null ? temperatureTargets[closest] : null;
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
