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

  const AlertResult({
    required this.type,
    required this.severity,
    required this.actualValue,
    required this.threshold,
    this.messageRu,
    this.messageUz,
  });

  @override
  List<Object?> get props => [type, severity, actualValue, threshold];
}

class NormsData {
  final double mortalityThresholdPercent;
  final Map<int, double> weeklyWeightTargets;
  final double weightDeviationPercent;
  final Map<int, double> dailyFeedPerBird;
  final Map<int, double> temperatureTargets;

  const NormsData({
    required this.mortalityThresholdPercent,
    required this.weeklyWeightTargets,
    required this.weightDeviationPercent,
    required this.dailyFeedPerBird,
    required this.temperatureTargets,
  });

  factory NormsData.fromJson(Map<String, dynamic> json) {
    // Parse norms.json structure
    final mortality = json['mortality'] as Map<String, dynamic>;
    final weight = json['weight'] as Map<String, dynamic>;
    final feed = json['feed'] as Map<String, dynamic>;
    final temp = json['temperature'] as Map<String, dynamic>;

    return NormsData(
      mortalityThresholdPercent: (mortality['daily_threshold_percent'] as num).toDouble(),
      weeklyWeightTargets: (weight['weekly_targets_grams'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(int.parse(k), (v as num).toDouble())),
      weightDeviationPercent: (weight['deviation_percent'] as num).toDouble(),
      dailyFeedPerBird: (feed['daily_grams_per_bird'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(int.parse(k), (v as num).toDouble())),
      temperatureTargets: (temp['targets_celsius'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(int.parse(k), (v as num).toDouble())),
    );
  }

  /// Get the target weight for the closest checkpoint at or before the given day.
  double? weightTargetForDay(int day) {
    final checkpoints = weeklyWeightTargets.keys.toList()..sort();
    int? closestCheckpoint;
    for (final cp in checkpoints) {
      if (cp <= day) closestCheckpoint = cp;
    }
    return closestCheckpoint != null ? weeklyWeightTargets[closestCheckpoint] : null;
  }
}
