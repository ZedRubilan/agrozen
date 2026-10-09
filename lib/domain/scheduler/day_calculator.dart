/// Calculates the batch day number from arrival date.
/// Day 1 = arrival date itself.
class DayCalculator {
  /// Returns the batch day (1-based) for a given arrival date.
  static int calculateBatchDay(DateTime arrivalDate, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final arrivalLocal = DateTime(arrivalDate.year, arrivalDate.month, arrivalDate.day);
    final todayLocal = DateTime(today.year, today.month, today.day);
    return todayLocal.difference(arrivalLocal).inDays + 1;
  }

  /// Returns true if the batch is still in the 42-day growing period.
  static bool isBatchActive(DateTime arrivalDate, {DateTime? now}) {
    final day = calculateBatchDay(arrivalDate, now: now);
    return day >= 1 && day <= 42;
  }

  /// Returns the week number (1-based) for a batch day.
  static int weekNumber(int batchDay) {
    return ((batchDay - 1) ~/ 7) + 1;
  }

  /// Returns days remaining in the 42-day cycle.
  static int daysRemaining(DateTime arrivalDate, {DateTime? now}) {
    final day = calculateBatchDay(arrivalDate, now: now);
    return (42 - day).clamp(0, 42);
  }
}
