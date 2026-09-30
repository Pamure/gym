import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Android reminders. Web intentionally uses the in-app dashboard instead.
///
/// A 06:30 alarm is best-effort: Android can still silence notifications,
/// battery restrictions and Do Not Disturb can override it. When the user
/// grants Alarms & reminders access, the wake-up notification uses an exact
/// alarm; otherwise it degrades to an inexact alarm rather than breaking.
class ReminderService {
  static final FlutterLocalNotificationsPlugin _p =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static bool _exactAlarmsAllowed = false;

  static const _channelId = 'ironforge_daily';
  static const idWakeUp = 1001;
  static const idKegel = 1003;
  static const idGymBase = 1010; // 1011..1016, Monday..Saturday

  static Future<void> init() async {
    if (_ready || kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      }
      await _p.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _ready = true;
    } catch (_) {
      // The app remains usable if a device or web target has no notifications.
    }
  }

  static Future<bool> ensurePermission({bool requestExactAlarm = false}) async {
    if (!_ready || kIsWeb) return false;
    try {
      final android = _p
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final notifications =
          await android?.requestNotificationsPermission() ?? false;
      // Android 12+ may open the app's Alarms & reminders settings here.
      // It is optional; ordinary reminders are still scheduled if declined.
      _exactAlarmsAllowed = requestExactAlarm
          ? (await android?.requestExactAlarmsPermission() ?? false)
          : (await android?.canScheduleExactNotifications() ?? false);
      return notifications;
    } catch (_) {
      return false;
    }
  }

  static AndroidScheduleMode get _scheduleMode => _exactAlarmsAllowed
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  static NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'IronForge reminders',
      channelDescription:
          'Wake-up, workout and recovery reminders from IronForge',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
    ),
  );

  static Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!_ready || kIsWeb) return;
    try {
      await _p.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: _nextInstance(hour, minute),
        notificationDetails: _details,
        androidScheduleMode: _scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  static Future<void> scheduleWeekly({
    required int id,
    required int weekday,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!_ready || kIsWeb) return;
    try {
      await _p.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: _nextInstanceOfWeekday(weekday, hour, minute),
        notificationDetails: _details,
        androidScheduleMode: _scheduleMode,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (_) {}
  }

  static Future<void> cancel(int id) async {
    if (!_ready || kIsWeb) return;
    try {
      await _p.cancel(id: id);
    } catch (_) {}
  }

  static Future<void> cancelAll() async {
    if (!_ready || kIsWeb) return;
    try {
      await _p.cancelAll();
    } catch (_) {}
  }

  static Future<void> scheduleForPrefs(
    dynamic state,
    bool enabled, {
    bool requestExactAlarm = false,
  }) async {
    if (!_ready && !kIsWeb) await init();
    if (kIsWeb) return;

    await cancel(idWakeUp);
    await cancel(idKegel);
    for (var d = DateTime.monday; d <= DateTime.saturday; d++) {
      await cancel(idGymBase + d);
      // Also cancel the prep reminder from older app versions.
      await cancel(idGymBase + d + 100);
    }
    if (!enabled) return;

    final permission = await ensurePermission(
      requestExactAlarm: requestExactAlarm,
    );
    if (!permission) return;

    int? parse(String value) {
      final p = value.split(':');
      if (p.length != 2) return null;
      final hour = int.tryParse(p[0]);
      final minute = int.tryParse(p[1]);
      if (hour == null || minute == null || hour > 23 || minute > 59) {
        return null;
      }
      return hour * 60 + minute;
    }

    final wake = parse(state.pref('wake_time', '06:30'));
    final gym = parse(state.pref('gym_time', '17:00'));
    final kegel = parse(state.pref('reminder_time', '21:00'));

    if (wake != null) {
      await scheduleDaily(
        id: idWakeUp,
        hour: wake ~/ 60,
        minute: wake % 60,
        title: 'Good morning, athlete 🌅',
        body: 'Water, shoes, then check today\'s simple session in IronForge.',
      );
    }

    // Strength is Mon/Wed/Fri. Optional cardio/mobility is Tue/Thu/Sat.
    // Sunday gym notification is omitted because it is a full rest day.
    // The user-selected wake-up and optional recovery reminders remain daily.
    if (gym != null) {
      for (var d = DateTime.monday; d <= DateTime.saturday; d++) {
        final strengthDay = d.isOdd;
        await scheduleWeekly(
          id: idGymBase + d,
          weekday: d,
          hour: gym ~/ 60,
          minute: gym % 60,
          title: strengthDay ? 'Strength session 💪' : 'Optional movement 🚶',
          body: strengthDay
              ? 'Warm up, use the first exercise, and keep 2–3 good reps in reserve.'
              : 'Easy cardio or mobility only. You should be able to talk normally.',
        );
      }
    }

    if (kegel != null) {
      await scheduleDaily(
        id: idKegel,
        hour: kegel ~/ 60,
        minute: kegel % 60,
        title: 'Recovery check-in',
        body: 'Optional gentle mobility or pelvic-floor practice. Stop if uncomfortable.',
      );
    }
  }

  static tz.TZDateTime _nextInstanceOfWeekday(
    int weekday,
    int hour,
    int minute,
  ) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (next.weekday != weekday || !next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  static tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    return next;
  }
}
