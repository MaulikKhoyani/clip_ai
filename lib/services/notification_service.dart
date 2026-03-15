import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clip_ai/core/routing/app_router.dart';
import 'package:clip_ai/data/datasources/supabase_datasource.dart';

/// Must be a top-level function — called by Firebase when a message
/// arrives while the app is in the background or terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.messageId}');
}

/// Hive keys for per-type notification preferences.
class NotifPrefs {
  static const enabled = 'notif_enabled';
  static const exportComplete = 'notif_export_complete';
  static const newTemplates = 'notif_new_templates';
  static const promotions = 'notif_promotions';
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  SupabaseDataSource? _datasource;

  static const _channelId = 'clipai_high_importance';
  static const _channelName = 'ClipAI Notifications';
  static const _channelDesc = 'Important notifications from ClipAI';

  static const _androidChannel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDesc,
    importance: Importance.high,
  );

  Future<void> initialize(SupabaseDataSource datasource) async {
    _datasource = datasource;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermissions();
    await _setupLocalNotifications();

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Tapped while app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // App launched via notification (terminated state) — defer navigation
    // until router is ready by storing the route for the splash screen.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      final route = initial.data['route'] as String?;
      if (route != null) {
        Hive.box('settings').put('pending_notification_route', route);
      }
    }

    // Get token and upload if user is already logged in
    // getToken() throws on iOS simulator (no APNs) — safe to ignore
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM Token: $token');
      if (token != null) await _uploadTokenIfLoggedIn(token);
    } catch (e) {
      debugPrint('FCM getToken failed (expected on simulator): $e');
    }

    // Upload refreshed token
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM Token refreshed: $newToken');
      await _uploadTokenIfLoggedIn(newToken);
    });
  }

  /// Call this after the user successfully signs in so their token is saved.
  Future<void> onUserLoggedIn(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null && _datasource != null) {
        try {
          await _datasource!.saveFcmToken(userId, token);
        } catch (e) {
          debugPrint('FCM token upload failed: $e');
        }
      }
    } catch (e) {
      debugPrint('FCM getToken failed on login (expected on simulator): $e');
    }
  }

  Future<void> _uploadTokenIfLoggedIn(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null && _datasource != null) {
      try {
        await _datasource!.saveFcmToken(userId, token);
      } catch (e) {
        debugPrint('FCM token upload failed: $e');
      }
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('FCM permission: ${settings.authorizationStatus}');
    } else if (Platform.isAndroid) {
      // Android 13+ requires explicit notification permission
      final status = await Permission.notification.status;
      if (status.isDenied) {
        await Permission.notification.request();
      }
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _navigateTo(payload);
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Check master switch
    final box = Hive.box('settings');
    final masterEnabled = box.get(NotifPrefs.enabled, defaultValue: true) as bool;
    if (!masterEnabled) return;

    // Check per-type preference
    final type = message.data['type'] as String?;
    if (!_isTypeEnabled(type, box)) return;

    // On Android show a local heads-up notification
    if (Platform.isAndroid) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: message.data['route'] as String?,
      );
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route != null && route.isNotEmpty) {
      _navigateTo(route);
    }
  }

  void _navigateTo(String route) {
    try {
      appRouter.go(route);
    } catch (e) {
      debugPrint('FCM navigation failed for route "$route": $e');
    }
  }

  bool _isTypeEnabled(String? type, Box box) {
    switch (type) {
      case 'export_complete':
        return box.get(NotifPrefs.exportComplete, defaultValue: true) as bool;
      case 'new_templates':
        return box.get(NotifPrefs.newTemplates, defaultValue: true) as bool;
      case 'promotion':
        return box.get(NotifPrefs.promotions, defaultValue: true) as bool;
      default:
        return true;
    }
  }

  /// Returns whether the system notification permission is granted.
  Future<bool> isPermissionGranted() async {
    if (Platform.isIOS) {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } else {
      return Permission.notification.isGranted;
    }
  }

  /// Requests notification permission (Android 13+).
  /// Returns true if granted.
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }
    if (Platform.isIOS) {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    }
    return false;
  }

  Future<String?> getToken() => _messaging.getToken();
}
