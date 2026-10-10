import 'alert_models.dart';

/// Pure business logic — NO AI, NO network calls.
/// Compares diary entries against norms.json thresholds.
class AlertEngine {
  final NormsData norms;

  const AlertEngine(this.norms);

  /// Check if daily mortality exceeds threshold.
  AlertResult? checkMortality({
    required int deaths,
    required int currentCount,
  }) {
    if (currentCount <= 0 || deaths <= 0) return null;
    final rate = deaths / currentCount * 100;
    if (rate > norms.mortalityThresholdPercent) {
      return AlertResult(
        type: AlertType.highMortality,
        severity: rate > norms.mortalityThresholdPercent * 3
            ? AlertSeverity.critical
            : AlertSeverity.warning,
        actualValue: rate,
        threshold: norms.mortalityThresholdPercent,
        messageRu: 'Внимание! Падёж за сутки ($deaths голов, ${rate.toStringAsFixed(1)}%) выше нормы. Срочно обратитесь к ветеринару!',
        messageUz: "Diqqat! Sutkalik nobodlik ($deaths bosh, ${rate.toStringAsFixed(1)}%) me'yordan yuqori. Zudlik bilan veterinarga murojaat qiling!",
        messageEn: 'Warning! Daily mortality ($deaths birds, ${rate.toStringAsFixed(1)}%) exceeds norm. Contact a veterinarian immediately!',
      );
    }
    return null;
  }

  /// Check if weight is significantly below norm for the given day.
  AlertResult? checkWeight({
    required double weightGrams,
    required int batchDay,
  }) {
    final target = norms.weightTargetForDay(batchDay);
    if (target == null || weightGrams <= 0) return null;
    final deviation = (target - weightGrams) / target * 100;
    if (deviation > norms.weightDeviationPercent) {
      return AlertResult(
        type: AlertType.lowWeight,
        severity: deviation > norms.weightDeviationPercent * 2
            ? AlertSeverity.critical
            : AlertSeverity.warning,
        actualValue: weightGrams,
        threshold: target,
        messageRu: 'Вес птицы (${weightGrams.toStringAsFixed(0)}г) значительно ниже нормы (${target.toStringAsFixed(0)}г) для дня $batchDay. Проверьте кормление и обратитесь к ветеринару.',
        messageUz: "Parranda og'irligi (${weightGrams.toStringAsFixed(0)}g) $batchDay-kun uchun me'yordan (${target.toStringAsFixed(0)}g) ancha past. Oziqlantirish tekshiring va veterinarga murojaat qiling.",
        messageEn: 'Flock weight (${weightGrams.toStringAsFixed(0)}g) is significantly below target (${target.toStringAsFixed(0)}g) for Day $batchDay. Review feeding and contact your veterinarian.',
      );
    }
    return null;
  }

  /// Run all checks and return list of triggered alerts.
  List<AlertResult> runAllChecks({
    required int batchDay,
    int? deaths,
    int? currentCount,
    double? weightGrams,
  }) {
    final alerts = <AlertResult>[];
    if (deaths != null && currentCount != null) {
      final mortalityAlert = checkMortality(
        deaths: deaths,
        currentCount: currentCount,
      );
      if (mortalityAlert != null) alerts.add(mortalityAlert);
    }
    if (weightGrams != null) {
      final weightAlert = checkWeight(
        weightGrams: weightGrams,
        batchDay: batchDay,
      );
      if (weightAlert != null) alerts.add(weightAlert);
    }
    return alerts;
  }
}
