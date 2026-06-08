import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'analytics_events.dart';

class AnalyticsService {
  AnalyticsService._({
    required FirebaseAnalytics? analytics,
    required FirebaseCrashlytics? crashlytics,
    required this.isEnabled,
  }) : _analytics = analytics,
       _crashlytics = crashlytics;

  final FirebaseAnalytics? _analytics;
  final FirebaseCrashlytics? _crashlytics;
  final bool isEnabled;

  /// Creates a disabled instance without touching any Firebase singletons.
  AnalyticsService._disabled()
    : _analytics = null,
      _crashlytics = null,
      isEnabled = false;

  static Future<AnalyticsService> create({required bool firebaseReady}) async {
    if (!firebaseReady) {
      return AnalyticsService._disabled();
    }

    // Only access Firebase singletons when Firebase was successfully initialized.
    final analytics = FirebaseAnalytics.instance;
    final crashlytics = FirebaseCrashlytics.instance;

    // Pass uncaught Flutter errors to Crashlytics.
    FlutterError.onError = crashlytics.recordFlutterFatalError;

    // Pass uncaught async errors to Crashlytics.
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    // Set basic Crashlytics custom keys.
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      await crashlytics.setCustomKey('app_version', packageInfo.version);
      await crashlytics.setCustomKey('build_number', packageInfo.buildNumber);
      await crashlytics.setCustomKey('platform', Platform.operatingSystem);
    } catch (e) {
      debugPrint('AnalyticsService: $e');
    }

    return AnalyticsService._(
      analytics: analytics,
      crashlytics: crashlytics,
      isEnabled: true,
    );
  }

  // -- Analytics --

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!isEnabled) return;
    try {
      await _analytics!.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('AnalyticsService: $e');
    }
  }

  Future<void> setUserId(String? id) async {
    if (!isEnabled) return;
    try {
      await _analytics!.setUserId(id: id);
      await _crashlytics!.setUserIdentifier(id ?? '');
    } catch (e) {
      debugPrint('AnalyticsService: $e');
    }
  }

  Future<void> logScreenView({required String screenName}) async {
    if (!isEnabled) return;
    try {
      await _analytics!.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('AnalyticsService: $e');
    }
  }

  // Convenience methods for required events

  Future<void> logAppOpen() => logEvent(name: AnalyticsEvents.appOpen);

  Future<void> logLogin() => logEvent(name: AnalyticsEvents.authCompleted);

  Future<void> logSignup() =>
      logEvent(name: AnalyticsEvents.onboardingCompleted);

  Future<void> logLogout() => logEvent(name: AnalyticsEvents.userSignedOut);

  Future<void> logNotificationReceived() =>
      logEvent(name: 'notification_received');

  Future<void> logNotificationOpened() => logEvent(name: 'notification_opened');

  Future<void> logForceUpdateShown() => logEvent(name: 'force_update_shown');

  Future<void> logOptionalUpdateShown() =>
      logEvent(name: 'optional_update_shown');

  // -- Crashlytics --

  Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) async {
    if (!isEnabled) return;
    try {
      await _crashlytics!.recordError(error, stack, fatal: fatal);
    } catch (e) {
      debugPrint('AnalyticsService: $e');
    }
  }

  Future<void> setCustomKey(String key, Object value) async {
    if (!isEnabled) return;
    try {
      await _crashlytics!.setCustomKey(key, value);
    } catch (e) {
      debugPrint('AnalyticsService: $e');
    }
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService._disabled(),
);
