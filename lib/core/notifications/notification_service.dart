import 'dart:async';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/gen/app_localizations.dart';
import '../config/endpoints.dart';
import '../domain/wire_enums.dart';
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

  static Future<void> initializeLocalNotifications({Locale? locale}) async {
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
      // Android freezes a channel's user-facing name/description the first
      // time it is created; later calls cannot rename it. Localize from the
      // persisted app locale (or the explicit [locale]) so the very first
      // launch records it in the user's language.
      final l10n = await _l10nFor(locale ?? await _savedLocale());
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          'flatmates_messages',
          l10n.notifChannelMessagesName,
          description: l10n.notifChannelMessagesDesc,
          importance: Importance.high,
        ),
      );
    }
  }

  /// Loads [AppLocalizations] for [locale], falling back to English.
  static Future<AppLocalizations> _l10nFor(Locale locale) async {
    try {
      return await AppLocalizations.delegate.load(locale);
    } catch (e) {
      debugPrint('NotificationService._l10nFor: $e');
      return AppLocalizations.delegate.load(const Locale('en'));
    }
  }

  /// Best-effort read of the persisted app locale; defaults to English.
  static Future<Locale> _savedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(PrefKeys.localeLanguageCode);
      if (languageCode == null) return const Locale('en');
      return Locale(languageCode, prefs.getString(PrefKeys.localeCountryCode));
    } catch (e) {
      debugPrint('NotificationService._savedLocale: $e');
      return const Locale('en');
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    _setPendingRoute(response.payload);
  }

  static String? _pendingRoute;

  /// Called when a tap stores a route, so a running app can navigate at once
  /// instead of waiting for the next resume or rebuild. Set by `App`.
  static VoidCallback? onPendingRoute;

  static void _setPendingRoute(String? route) {
    if (route == null || route.isEmpty) return;
    _pendingRoute = route;
    onPendingRoute?.call();
  }

  /// Drops a captured-but-unconsumed route. A push tapped before an abandoned
  /// login belongs to the account that received it, so it must not replay for
  /// whichever account signs in next on this device.
  static void clearPendingRoute() {
    _pendingRoute = null;
  }

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

      final settings = await FirebaseMessaging.instance.requestPermission();

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
      unawaited(_onMessageSub?.cancel());
      unawaited(_onMessageOpenedAppSub?.cancel());
      unawaited(_onTokenRefreshSub?.cancel());
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
    if (!_shouldShowForegroundNotification(message)) {
      debugPrint(
        'NotificationService: suppressed foreground notification '
        '(type_key=${message.data['type_key']})',
      );
      return;
    }

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

  /// Returns false when the user has opted out of this notification category
  /// via local prefs (mirrors the [SettingsController] message and promotion
  /// switches). The category comes from the top-level `type_key` of the push
  /// data only.
  bool _shouldShowForegroundNotification(RemoteMessage message) {
    final prefs = _ref.read(appPreferencesProvider);
    return foregroundPushAllowed(
      message.data['type_key']?.toString(),
      messagesOn: prefs.getBoolOrDefault(PrefKeys.notifNewMessages, true),
      promotionsOn: prefs.getBoolOrDefault(PrefKeys.notifPromotions, false),
    );
  }

  void _handleMessageTap(RemoteMessage message) {
    _setPendingRoute(message.data['route'] as String?);
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      await _ref
          .read(apiClientProvider)
          .post(
            FlatmatesEndpoints.notificationRegister,
            data: deviceRegisterBody(token, isIOS: Platform.isIOS),
          );
    } catch (e) {
      // Token sync is best-effort; do not block UX.
      debugPrint('NotificationService._sendTokenToServer failed: $e');
    }
  }

  Future<void> clearToken() async {
    if (!_messagingEnabled) return;
    try {
      if (Platform.isIOS) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null || apnsToken.isEmpty) return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _ref
          .read(apiClientProvider)
          .delete(
            FlatmatesEndpoints.notificationUnregister,
            data: deviceUnregisterBody(token),
          );
    } on FirebaseException catch (e) {
      if (e.plugin == 'firebase_messaging' && e.code == 'apns-token-not-set') {
        return;
      }
      debugPrint('NotificationService.clearToken failed: $e');
    } catch (e) {
      // Best-effort
      debugPrint('NotificationService.clearToken failed: $e');
    }
  }
}

/// The `POST /notifications/devices/register` body. `app_key` is required; the
/// platform is the wire value (`ios` or `android`).
@visibleForTesting
Map<String, dynamic> deviceRegisterBody(String token, {required bool isIOS}) =>
    {
      'token': token,
      'platform': (isIOS ? DevicePlatform.ios : DevicePlatform.android).wire,
      'app_key': AppKey.flatmates.wire,
    };

/// The `DELETE /notifications/devices/unregister` body: the token in JSON, not
/// in the query string.
@visibleForTesting
Map<String, dynamic> deviceUnregisterBody(String token) => {'token': token};

/// Push `type_key` values (see the backend notification registry) for a chat
/// message.
const _messageTypeKeys = {'flatmate_new_message', 'chat_message'};

/// Push `type_key` values for marketing sends.
const _promotionTypeKeys = {
  'promotion_generic',
  'discount_offer',
  'win_back',
  'upsell_suggestion',
  'onboarding_nudge',
  'property_recommendation',
  'daily_digest',
};

/// Whether a push in the foreground is shown, given its top-level `type_key`.
///
/// Only messages and promotions have a local switch. Every other category, and
/// a push with no `type_key`, is shown.
@visibleForTesting
bool foregroundPushAllowed(
  String? typeKey, {
  required bool messagesOn,
  required bool promotionsOn,
}) {
  final key = typeKey?.trim().toLowerCase() ?? '';
  if (_messageTypeKeys.contains(key)) return messagesOn;
  if (_promotionTypeKeys.contains(key)) return promotionsOn;
  return true;
}

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(ref),
);
