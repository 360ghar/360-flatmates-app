import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
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
  } catch (_) {
    // Firebase may not be configured; skip silently.
  }
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  await initializeDateFormatting();

  final config = AppConfig.fromEnvironment();

  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase may not be configured yet (e.g. missing google-services.json /
    // GoogleService-Info.plist). Allow the app to start so it can still be
    // developed and tested without Firebase.
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
      ],
      child: const App(),
    ),
  );
}
