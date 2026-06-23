import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/sleep_schedule.dart';

class ReminderService {
  ReminderService() : _plugin = FlutterLocalNotificationsPlugin();

  static const _bedtimeNotificationId = 1001;

  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  Future<bool> requestPermissionIfNeeded() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    final androidResult = await android?.requestNotificationsPermission();
    final iosResult = await ios?.requestPermissions(
      alert: true,
      badge: false,
      sound: true,
    );

    return (androidResult ?? true) && (iosResult ?? true);
  }

  Future<void> scheduleBedtimeReminder(SleepSchedule schedule) async {
    await cancelBedtimeReminder();

    if (!schedule.reminderEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    var target = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      schedule.bedtimeHour,
      schedule.bedtimeMinute,
    );
    if (target.isBefore(now)) target = target.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      id: _bedtimeNotificationId,
      title: '准备进入睡眠模式',
      body: '今晚的音景、冥想和定时器已经准备好了。',
      scheduledDate: target,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'skydogs_bedtime',
          '睡前提醒',
          channelDescription: '每日睡前提醒和定时通知',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(threadIdentifier: 'skydogs-bedtime'),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelBedtimeReminder() async {
    await _plugin.cancel(id: _bedtimeNotificationId);
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    }
  }
}