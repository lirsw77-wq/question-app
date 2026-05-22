import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      tz_data.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _notifications.initialize(initSettings);

      await _requestPermission();

      _initialized = true;
    } catch (e) {
      // Notification init failure should not crash the app
      _initialized = false;
    }
  }

  Future<void> _requestPermission() async {
    try {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.requestNotificationsPermission();
      }
    } catch (_) {}
  }

  Future<bool> _canScheduleExactAlarms() async {
    try {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.canScheduleExactNotifications() ?? false;
      }
    } catch (_) {}
    return false;
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> scheduleDailyReciteReminder() async {
    if (!_initialized) return;
    try {
      // Check if exact alarms are allowed (Android 12+)
      final canSchedule = await _canScheduleExactAlarms();
      if (!canSchedule) return;

      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'recite_reminder_channel',
          '背诵复习提醒',
          channelDescription: '每日背诵复习提醒通知',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

      await _notifications.zonedSchedule(
        0,
        '背诵复习提醒',
        '今日背诵任务待完成，快来复习吧！',
        _nextInstanceOfTime(8, 0),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  Future<void> scheduleDailyCurrentAffairsReminder() async {
    if (!_initialized) return;
    try {
      // Check if exact alarms are allowed (Android 12+)
      final canSchedule = await _canScheduleExactAlarms();
      if (!canSchedule) return;

      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'current_affairs_channel',
          '时政更新提醒',
          channelDescription: '每日时政热点更新提醒通知',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

      await _notifications.zonedSchedule(
        1,
        '时政更新',
        '今日时政热点已更新，点击查看！',
        _nextInstanceOfTime(9, 0),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      await _notifications.cancelAll();
    } catch (_) {}
  }
}
