import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/analytics/analytics_service.dart';
import 'core/config/app_config.dart';
import 'core/config/env_loader.dart';
import 'core/notifications/notification_service.dart';
import 'core/providers.dart';
import 'core/storage/app_preferences.dart';
import 'core/storage/secure_kv_store.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    // Initialize local notifications so background messages can be displayed.
    await NotificationService.initializeLocalNotifications();

    // Show notification for data-only messages (no notification payload).
    if (message.notification == null && message.data.isNotEmpty) {
      final title = message.data['title'] ?? '360 FlatMates';
      final body = message.data['body'] ?? message.data['message'] ?? '';
      final route = message.data['route'];
      if (body.isNotEmpty) {
        await NotificationService.showLocalNotification(
          title: title,
          body: body,
          payload: route,
        );
      }
    }
  } catch (e) {
    debugPrint('_firebaseMessagingBackgroundHandler: $e');
  }
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  await initializeDateFormatting();

  final AppConfig config;
  try {
    config = AppConfig.fromEnvironment();
  } catch (error) {
    runApp(_ConfigErrorApp(message: error.toString()));
    return;
  }

  var firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
  } catch (e) {
    // Firebase may not be configured yet (e.g. missing google-services.json /
    // GoogleService-Info.plist). Allow the app to start so it can still be
    // developed and tested without Firebase.
    debugPrint('[bootstrap] Firebase init skipped: $e');
  }
  if (firebaseInitialized) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Initialize Crashlytics + Analytics.
  final analyticsService = await AnalyticsService.create(
    firebaseReady: firebaseInitialized,
  );

  // Initialize the local notifications plugin early so it is ready before
  // the widget tree mounts and before any foreground / background messages
  // arrive.
  await NotificationService.initializeLocalNotifications();

  await Supabase.initialize(
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
  );

  final preferences = await AppPreferences.create();
  const secureStore = SecureKvStore();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        appPreferencesProvider.overrideWithValue(preferences),
        secureStoreProvider.overrideWithValue(secureStore),
        notificationServiceProvider.overrideWith(
          (ref) =>
              NotificationService(ref, messagingEnabled: firebaseInitialized),
        ),
        analyticsServiceProvider.overrideWithValue(analyticsService),
      ],
      child: const App(),
    ),
  );
}

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          minimum: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_outlined, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Configuration required',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  '$message\n\nRun with --dart-define values for API_BASE_URL, SUPABASE_URL, and SUPABASE_PUBLISHABLE_KEY.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
