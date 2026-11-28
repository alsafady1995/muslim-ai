import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../data/groups_repository.dart';
import 'config.dart';
import 'notifications.dart';

/// Push notifications for family-group calls (Firebase Cloud Messaging).
///
/// Off until the Firebase keys are in the build env (BLOCKERS.md item 35). Without them the app
/// works as before and members see calls when they open the app.
class GroupPush {
  static bool _started = false;
  static GroupsRepository? _repo;
  static StreamSubscription<String>? _tokenSub;

  /// Called when a notification for a group is tapped (wired to the router in app.dart).
  static void Function(String groupId)? onOpenGroup;

  /// Called when a call arrives while the app is open (refreshes the lists).
  static VoidCallback? onCallReceived;

  static bool get configured =>
      !kIsWeb &&
      !AppConfig.demoMode &&
      AppConfig.firebaseProjectId.isNotEmpty &&
      AppConfig.firebaseSenderId.isNotEmpty &&
      (defaultTargetPlatform == TargetPlatform.iOS ? AppConfig.firebaseIosAppId : AppConfig.firebaseAndroidAppId).isNotEmpty;

  static FirebaseOptions get _options {
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    return FirebaseOptions(
      apiKey: ios ? AppConfig.firebaseIosApiKey : AppConfig.firebaseAndroidApiKey,
      appId: ios ? AppConfig.firebaseIosAppId : AppConfig.firebaseAndroidAppId,
      messagingSenderId: AppConfig.firebaseSenderId,
      projectId: AppConfig.firebaseProjectId,
      iosBundleId: ios ? 'app.muslimai.mobile' : null,
    );
  }

  static Future<bool> _init(GroupsRepository repo) async {
    if (!configured) return false;
    _repo = repo;
    if (_started) return true;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: _options);
      await Reminders.init();
      final fm = FirebaseMessaging.instance;
      // iOS: show the banner even when the app is open.
      await fm.setForegroundNotificationPresentationOptions(alert: true, sound: true);
      FirebaseMessaging.onMessage.listen((m) {
        onCallReceived?.call();
        // Android doesn't show FCM notifications while the app is in the foreground.
        if (defaultTargetPlatform == TargetPlatform.android && m.notification != null) {
          Reminders.showGroupCall(m.notification!.title ?? '', m.notification!.body ?? '');
        }
      });
      FirebaseMessaging.onMessageOpenedApp.listen(_open);
      final initial = await fm.getInitialMessage();
      if (initial != null) _open(initial);
      _started = true;
      return true;
    } catch (e) {
      debugPrint('push init failed: $e');
      return false;
    }
  }

  static void _open(RemoteMessage m) {
    final g = m.data['group_id'];
    if (g is String && g.isNotEmpty) onOpenGroup?.call(g);
  }

  /// At app start: registers this phone if notifications are already allowed. Never prompts.
  static Future<void> sync(GroupsRepository repo) async {
    if (!await _init(repo)) return;
    final s = await FirebaseMessaging.instance.getNotificationSettings();
    if (s.authorizationStatus == AuthorizationStatus.authorized ||
        s.authorizationStatus == AuthorizationStatus.provisional) {
      await _register();
    }
  }

  /// When the user creates or joins a group: asks for permission (once) and registers.
  static Future<void> enable(GroupsRepository repo) async {
    if (!await _init(repo)) return;
    try {
      final s = await FirebaseMessaging.instance.requestPermission();
      if (s.authorizationStatus == AuthorizationStatus.denied) return;
      await _register();
    } catch (e) {
      debugPrint('push permission failed: $e');
    }
  }

  static Future<void> _register() async {
    try {
      final fm = FirebaseMessaging.instance;
      final token = await fm.getToken();
      final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
      if (token != null) await _repo?.registerPushToken(token, platform);
      _tokenSub ??= fm.onTokenRefresh.listen((t) => _repo?.registerPushToken(t, platform));
    } catch (e) {
      debugPrint('push register failed: $e');
    }
  }
}
