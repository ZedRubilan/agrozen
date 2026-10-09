import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the daily 07:00 "here is your plan for today" reminder.
///
/// This is feature #1 from the MVP plan ("Каждое утро: «День 9: температура
/// такая-то, сегодня сделай вот это»"). It is deliberately local-only and
/// deterministic: no AI, no network, so it cannot hallucinate and works
/// offline in a village with no connectivity.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int dailyPlanNotificationId = 1001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Sets up the notification channel. Safe to call more than once.
  ///
  /// Returns true on success; false on any platform failure so callers can
  /// stay quiet rather than crash on a device without notification support.
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      tz_data.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _plugin.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
          macOS: DarwinInitializationSettings(),
          linux: LinuxInitializationSettings(defaultActionName: 'Open'),
        ),
      );

      _initialized = true;
      return true;
    } catch (e, stack) {
      if (e is! Error) {
        debugPrint('NotificationService.initialize failed: $e\n$stack');
      }
      _initialized = false;
      return false;
    }
  }

  /// Requests OS permission on iOS / Android 13+. Returns true when granted.
  Future<bool> requestPermissions() async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) return false;
    }

    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      // Other platforms have no permission gate.
      return true;
    } catch (e) {
      debugPrint('NotificationService.requestPermissions failed: $e');
      return false;
    }
  }

  /// Schedules a repeating 07:00 notification in [Asia/Tashkent].
  ///
  /// [batchDay] is only used for the notification body so the farmer can see
  /// which day of the cycle it is without opening the app.
  Future<bool> scheduleDailyMorningNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) return false;
    }

    try {
      final scheduled = _next7amTashkent();

      await _plugin.zonedSchedule(
        dailyPlanNotificationId,
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'agrozen_daily_plan',
            'Kunlik reja',
            channelDescription: "Har kuni ertalab 7:00 da partiya reja eslatmasi",
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      return true;
    } catch (e, stack) {
      debugPrint('scheduleDailyMorningNotification failed: $e\n$stack');
      return false;
    }
  }

  /// Cancels the daily reminder.
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('NotificationService.cancelAll failed: $e');
    }
  }

  /// The next 07:00 in Tashkent; tomorrow's if 07:00 already passed today.
  tz.TZDateTime _next7amTashkent() {
    const tashkent = 'Asia/Tashkent';
    final location = tz.getLocation(tashkent);
    final now = tz.TZDateTime.now(location);
    var next = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      7,
    );
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }
}

