import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Daily reminder scheduling (Android APK). No-ops on web — the web build
/// shows in-app reminders instead (dashboard banner + badge).
class ReminderService {
  static final FlutterLocalNotificationsPlugin _p =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _channelId = 'ironforge_daily';

  /// Notification ids — fixed so re-scheduling replaces cleanly.
  static const idWakeUp = 1001;
  static const idKegel = 1003;

  /// Gym reminder = one WEEKLY notification per training weekday (Mon..Sat).
  /// ids 1010..1015. Sunday never fires — gym is closed.
  static const idGymBase = 1010;

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
      // notifications unavailable — app keeps working
    }
  }

  static Future<bool> ensurePermission() async {
    if (!_ready || kIsWeb) return false;
    try {
      final android = _p.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

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
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Daily reminders',
            channelDescription: 'IronForge wake-up, gym and kegel reminders',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  /// Weekly repeating reminder on one weekday (e.g. every Monday 17:00).
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
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Daily reminders',
            channelDescription: 'IronForge wake-up, gym and kegel reminders',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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

  /// Schedule/cancel all three daily reminders from stored prefs.
  static Future<void> scheduleForPrefs(dynamic state, bool enabled) async {
    if (!_ready && !kIsWeb) await init();
    if (kIsWeb) return;
    await cancel(idWakeUp);
    await cancel(idKegel);
    for (var d = DateTime.monday; d <= DateTime.saturday; d++) {
      await cancel(idGymBase + d);
    }
    if (!enabled) return;
    final perm = await ensurePermission();
    if (!perm) return;
    int? parse(String v) {
      final p = v.split(':');
      if (p.length != 2) return null;
      final h = int.tryParse(p[0]);
      final m = int.tryParse(p[1]);
      if (h == null || m == null || h > 23 || m > 59) return null;
      return h * 60 + m;
    }

    final wake = parse(state.pref('wake_time', '06:30'));
    final gym = parse(state.pref('gym_time', '17:00'));
    final kegel = parse(state.pref('reminder_time', '21:00'));
    if (wake != null) {
      await scheduleDaily(
          id: idWakeUp, hour: wake ~/ 60, minute: wake % 60,
          title: 'Good morning, athlete 🌅',
          body: 'Water first, then check today\'s session in IronForge. Small steps daily.');
    }
    // One weekly notification per training day (Mon..Sat) — Sunday is rest,
    // gym closed, no notification. Fixes the old bug where the daily-repeat
    // reminder also fired on Sundays.
    if (gym != null) {
      for (var d = DateTime.monday; d <= DateTime.saturday; d++) {
        await scheduleWeekly(
            id: idGymBase + d, weekday: d,
            hour: gym ~/ 60, minute: gym % 60,
            title: 'Time to train 💪',
            body: 'Open IronForge → your session is waiting. Film your last set.');
      // Stricter 2nd reminder: morning prep reminder (2/day total, skip Sunday)
      for (var d = DateTime.monday; d <= DateTime.saturday; d++) {
        await scheduleWeekly(
            id: idGymBase + d + 100, weekday: d,
            hour: (gym ~/ 60 - 1 + 24) % 24, minute: gym % 60,
            title: 'Prep time - do not skip',
            body: 'Pack your bag, check your workout, and move. 6-day consistency = results. Skip Sunday - rest.');
      }
      }
    }
    if (kegel != null) {
      await scheduleDaily(
          id: idKegel, hour: kegel ~/ 60, minute: kegel % 60,
          title: 'Kegel check-in',
          body: '3 quick sets (hold/relax). Nobody will know you\'re doing them.');
    }
  }

  static tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (next.weekday != weekday || !next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  static tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    return next;
  }
}
