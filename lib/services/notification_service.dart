class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {}
  Future<void> scheduleDailyMorningNotification(int hour, int minute, String title, String body) async {}
  Future<void> cancelAll() async {}
}
