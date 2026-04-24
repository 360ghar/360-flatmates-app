import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../providers.dart';

class NotificationService {
  NotificationService(this._ref);

  final Ref _ref;
  bool _initialized = false;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'flatmates_messages',
          'Messages & Matches',
          description:
              'Notifications for new messages, matches, and visits',
          importance: Importance.high,
        ),
      );
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    final route = response.payload;
    if (route == null || route.isEmpty) return;
    _pendingRoute = route;
  }

  static String? _pendingRoute;

  static String? consumePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      if (Platform.isIOS) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      _onMessageSub =
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      _onMessageOpenedAppSub =
          FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }

      _onTokenRefreshSub =
          FirebaseMessaging.instance.onTokenRefresh.listen(_sendTokenToServer);
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _sendTokenToServer(token);
      }
    } catch (e) {
      _initialized = false;
      debugPrint('NotificationService.initialize() failed: $e');
    }
  }

  void dispose() {
    _onMessageSub?.cancel();
    _onMessageOpenedAppSub?.cancel();
    _onTokenRefreshSub?.cancel();
    _onMessageSub = null;
    _onMessageOpenedAppSub = null;
    _onTokenRefreshSub = null;
    _initialized = false;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'flatmates_messages',
          'Messages & Matches',
          channelDescription:
              'Notifications for new messages, matches, and visits',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['route'],
    );
  }

  void _handleMessageTap(RemoteMessage message) {
    final route = message.data['route'];
    if (route != null && route.isNotEmpty) {
      _pendingRoute = route;
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      await _ref.read(apiClientProvider).put(
            '/users/me',
            data: {'fcm_token': token},
          );
    } catch (_) {
      // Token sync is best-effort; do not block UX.
    }
  }

  Future<void> clearToken() async {
    try {
      await _ref.read(apiClientProvider).put(
            '/users/me',
            data: {'fcm_token': null},
          );
    } catch (_) {
      // Best-effort
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(ref),
);
