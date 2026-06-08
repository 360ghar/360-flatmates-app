import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/endpoints.dart';
import '../providers.dart';
import '../storage/app_preferences.dart';

class NotificationService {
  NotificationService(this._ref, {bool messagingEnabled = false})
    : _messagingEnabled = messagingEnabled;

  final Ref _ref;
  final bool _messagingEnabled;
  bool _initialized = false;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'flatmates_messages',
          'Messages & Matches',
          description: 'Notifications for new messages, matches, and visits',
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

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch,
      title,
      body,
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
      payload: payload,
    );
  }

  Future<void> initialize() async {
    if (_initialized) return;
    if (!_messagingEnabled) return;

    try {
      final prefs = _ref.read(appPreferencesProvider);

      final settings = await FirebaseMessaging.instance.requestPermission(
        
      );

      await prefs.setBool(PrefKeys.notifPermissionRequested, true);

      final authorizationStatus = settings.authorizationStatus;
      if (authorizationStatus == AuthorizationStatus.denied) {
        debugPrint(
          '[NotificationService] Permission denied — notifications disabled.',
        );
      } else if (authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint(
          '[NotificationService] Provisional permission granted — quiet notifications.',
        );
      } else if (authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('[NotificationService] Notification permission authorized.');
      } else if (authorizationStatus == AuthorizationStatus.notDetermined) {
        debugPrint(
          '[NotificationService] Permission not determined — may request again later.',
        );
      }

      _onMessageSub = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );
      _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(
        _handleMessageTap,
      );

      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }

      _onTokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
        _sendTokenToServer,
      );
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _sendTokenToServer(token);
      }
      _initialized = true;
    } catch (e) {
      _onMessageSub?.cancel();
      _onMessageOpenedAppSub?.cancel();
      _onTokenRefreshSub?.cancel();
      _onMessageSub = null;
      _onMessageOpenedAppSub = null;
      _onTokenRefreshSub = null;
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
    String? title;
    String? body;

    if (notification != null) {
      title = notification.title;
      body = notification.body;
    } else if (message.data.isNotEmpty) {
      // Data-only message: extract title/body from data payload.
      title = message.data['title'] ?? '360 FlatMates';
      body = message.data['body'] ?? message.data['message'];
    }

    if (title == null && body == null) return;

    showLocalNotification(
      title: title ?? '360 FlatMates',
      body: body ?? '',
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
      await _ref
          .read(apiClientProvider)
          .post(
            FlatmatesEndpoints.notificationRegister,
            data: {
              'token': token,
              'platform': Platform.isIOS ? 'ios' : 'android',
            },
          );
    } catch (e) {
      // Token sync is best-effort; do not block UX.
      debugPrint('NotificationService._sendTokenToServer failed: $e');
    }
  }

  Future<void> clearToken() async {
    if (!_messagingEnabled) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _ref
          .read(apiClientProvider)
          .delete(
            FlatmatesEndpoints.notificationUnregister,
            queryParameters: {'token': token},
          );
    } catch (e) {
      // Best-effort
      debugPrint('NotificationService.clearToken failed: $e');
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(ref),
);
