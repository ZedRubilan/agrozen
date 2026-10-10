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

  /// Check if house temperature deviates significantly from target for the day.
  AlertResult? checkTemperature({
    required int batchDay,
    required double actualTempCelsius,
    double? targetTempCelsius,
  }) {
    final target = targetTempCelsius ?? norms.temperatureTargetForDay(batchDay);
    if (target == null) return null;
    final diff = (actualTempCelsius - target).abs();
    if (diff > norms.tempDeviationCelsius) {
      final isHot = actualTempCelsius > target;
      return AlertResult(
        type: AlertType.highTemperature,
        severity: diff > norms.tempDeviationCelsius * 2
            ? AlertSeverity.critical
            : AlertSeverity.warning,
        actualValue: actualTempCelsius,
        threshold: target,
        messageRu: isHot
            ? 'Температура в птичнике (${actualTempCelsius.toStringAsFixed(1)}°C) выше нормы (${target.toStringAsFixed(1)}°C) для дня $batchDay. Усильте вентиляцию!'
            : 'Температура в птичнике (${actualTempCelsius.toStringAsFixed(1)}°C) ниже нормы (${target.toStringAsFixed(1)}°C) для дня $batchDay. Проверьте обогрев!',
        messageUz: isHot
            ? "Xona harorati (${actualTempCelsius.toStringAsFixed(1)}°C) $batchDay-kun me'yoridan (${target.toStringAsFixed(1)}°C) yuqori. Shamollatishni kuchaytiring!"
            : "Xona harorati (${actualTempCelsius.toStringAsFixed(1)}°C) $batchDay-kun me'yoridan (${target.toStringAsFixed(1)}°C) past. Isitishni tekshiring!",
        messageEn: isHot
            ? 'House temperature (${actualTempCelsius.toStringAsFixed(1)}°C) exceeds target (${target.toStringAsFixed(1)}°C) for Day $batchDay. Increase ventilation!'
            : 'House temperature (${actualTempCelsius.toStringAsFixed(1)}°C) is below target (${target.toStringAsFixed(1)}°C) for Day $batchDay. Check heating!',
      );
    }
    return null;
  }

  /// Check if cumulative flock mortality exceeds threshold (default 4.0%).
  AlertResult? checkCumulativeMortality({
    required int totalDeaths,
    required int initialCount,
    required int batchDay,
  }) {
    if (initialCount <= 0 || totalDeaths <= 0) return null;
    final rate = totalDeaths / initialCount * 100;
    if (rate > norms.cumulativeMortalityThresholdPercent) {
      return AlertResult(
        type: AlertType.highMortality,
        severity: rate > norms.cumulativeMortalityThresholdPercent * 2
            ? AlertSeverity.critical
            : AlertSeverity.warning,
        actualValue: rate,
        threshold: norms.cumulativeMortalityThresholdPercent,
        messageRu:
            'Общий падёж с начала партии ($totalDeaths из $initialCount голов, ${rate.toStringAsFixed(1)}%) превысил допустимый порог (${norms.cumulativeMortalityThresholdPercent.toStringAsFixed(1)}%) к дню $batchDay. Обратитесь к ветеринару!',
        messageUz:
            "Partiya boshidan umumiy nobodlik ($initialCount tadan $totalDeaths bosh, ${rate.toStringAsFixed(1)}%) $batchDay-kunga kelib ruxsat etilgan chegaradan (${norms.cumulativeMortalityThresholdPercent.toStringAsFixed(1)}%) oshdi. Veterinarga murojaat qiling!",
        messageEn:
            'Cumulative mortality ($totalDeaths of $initialCount birds, ${rate.toStringAsFixed(1)}%) has exceeded the threshold (${norms.cumulativeMortalityThresholdPercent.toStringAsFixed(1)}%) on Day $batchDay. Contact your veterinarian!',
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
    double? actualTempCelsius,
    int? totalDeaths,
    int? initialCount,
  }) {
    final alerts = <AlertResult>[];
    if (deaths != null && currentCount != null) {
      final mortalityAlert = checkMortality(
        deaths: deaths,
        currentCount: currentCount,
      );
      if (mortalityAlert != null) alerts.add(mortalityAlert);
    }
    if (totalDeaths != null && initialCount != null) {
      final cumAlert = checkCumulativeMortality(
        totalDeaths: totalDeaths,
        initialCount: initialCount,
        batchDay: batchDay,
      );
      if (cumAlert != null) alerts.add(cumAlert);
    }
    if (weightGrams != null) {
      final weightAlert = checkWeight(
        weightGrams: weightGrams,
        batchDay: batchDay,
      );
      if (weightAlert != null) alerts.add(weightAlert);
    }
    if (actualTempCelsius != null) {
      final tempAlert = checkTemperature(
        batchDay: batchDay,
        actualTempCelsius: actualTempCelsius,
      );
      if (tempAlert != null) alerts.add(tempAlert);
    }
    return alerts;
  }

  /// Alias for [runAllChecks] to evaluate a diary entry submission.
  List<AlertResult> evaluateDiaryEntry({
    required int batchDay,
    int? deaths,
    int? currentCount,
    double? weightGrams,
    double? actualTempCelsius,
    int? totalDeaths,
    int? initialCount,
  }) =>
      runAllChecks(
        batchDay: batchDay,
        deaths: deaths,
        currentCount: currentCount,
        weightGrams: weightGrams,
        actualTempCelsius: actualTempCelsius,
        totalDeaths: totalDeaths,
        initialCount: initialCount,
      );
}
