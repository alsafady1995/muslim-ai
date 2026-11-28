import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Local daily reminders (no push server needed for MVP).
class Reminders {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const morningAdhkar = 1;
  static const eveningAdhkar = 2;
  static const hifzReview = 3;
  static const streakSaver = 4;
  static const dailyReading = 5;
  static const trialEnding = 10;
  static const _groupCallBase = 1000;
  static int _groupCallSeq = 0;

  static Future<void> init() async {
    if (_ready || kIsWeb) return; // no local notifications on web
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    // Channel for family-group calls (FCM messages name it in android.notification.channel_id).
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel('groups', 'Group calls', importance: Importance.high));
    _ready = true;
  }

  /// Shows a group call that arrived while the app is open (Android only shows FCM banners
  /// in the background).
  static Future<void> showGroupCall(String title, String body) async {
    if (kIsWeb) return;
    await init();
    await _plugin.show(
      id: _groupCallBase + (_groupCallSeq++ % 50),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('groups', 'Group calls', importance: Importance.high, priority: Priority.high),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await init();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        await android?.requestNotificationsPermission() ??
        false;
    return granted;
  }

  /// Schedules (or replaces) a daily reminder at [hour]:[minute] local time.
  static Future<void> scheduleDaily(int id, String title, String body, int hour, int minute) async {
    if (kIsWeb) return;
    await init();
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (at.isBefore(now)) at = at.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: at,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('daily', 'Daily reminders', importance: Importance.high),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// One-off notification (e.g. the trial-ending reminder, a service message, not a sale).
  static Future<void> scheduleOnce(int id, String title, String body, DateTime at) async {
    if (kIsWeb) return;
    await init();
    final when = tz.TZDateTime.from(at, tz.local);
    if (when.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('account', 'Account', importance: Importance.high),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancel(int id) async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancel(id: id);
  }
}
