import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flatmates_app/core/config/app_config.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/network/auth_token_provider.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/core/storage/app_preferences.dart';
import 'package:flatmates_app/core/storage/auth_token_storage.dart';
import 'package:flatmates_app/core/storage/secure_kv_store.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/auth/data/auth_repository.dart';
import 'package:flatmates_app/features/settings/settings_controller.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

/// A minimal [AppConfig] for tests.
AppConfig fakeAppConfig() => const AppConfig(
      environment: AppEnvironment.dev,
      apiBaseUrl: 'https://api.test.example.com',
      supabaseUrl: 'https://test.supabase.co',
      supabaseAnonKey: 'test-anon-key',
      enableDebugLogs: false,
    );

// ---------------------------------------------------------------------------
// No-op infrastructure fakes
// ---------------------------------------------------------------------------

/// A no-op [AuthTokenProvider] for tests.
class FakeAuthTokenProvider implements AuthTokenProvider {
  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<void> clearSession() async {}
}

ApiClient _fakeApiClient() => ApiClient(
      baseUrl: 'https://test.example.com',
      tokenProvider: FakeAuthTokenProvider(),
      enableLogging: false,
    );

AuthTokenStorage _fakeAuthTokenStorage() => AuthTokenStorage(SecureKvStore());

AuthRepository _fakeAuthRepository() => AuthRepository(
      apiClient: _fakeApiClient(),
      tokenStorage: _fakeAuthTokenStorage(),
    );

// ---------------------------------------------------------------------------
// Fake controllers
// ---------------------------------------------------------------------------

/// A fake [AuthController] that overrides every method to avoid Supabase.
class FakeAuthController extends AuthController {
  FakeAuthController(Ref ref) : super(ref, _fakeAuthRepository());

  @override
  Future<void> checkSession() async {
    state = const AuthState.unauthenticated();
  }

  @override
  Future<void> requestOtp(String phone) async {
    state = AuthState.unauthenticated(phone: phone);
  }

  @override
  Future<bool> verifyOtp({required String phone, required String otp}) async {
    state = AuthState.authenticated(phone: phone);
    return true;
  }

  @override
  Future<bool> signInWithPassword({
    required String phone,
    required String password,
  }) async {
    state = AuthState.authenticated(phone: phone);
    return true;
  }

  @override
  Future<bool> signUpWithPassword({
    required String fullName,
    required String phone,
    required String password,
    String? email,
  }) async {
    state = AuthState.authenticated(phone: phone);
    return true;
  }

  @override
  Future<void> signOut() async {
    state = const AuthState.unauthenticated();
  }
}

/// A fake [SettingsController] that overrides load to avoid disk I/O.
class FakeSettingsController extends SettingsController {
  FakeSettingsController(AppPreferences prefs) : super(prefs);

  @override
  Future<void> load() async {
    state = state.copyWith(loaded: true);
  }
}

// ---------------------------------------------------------------------------
// Cached AppPreferences instance (created once per test isolate)
// ---------------------------------------------------------------------------

AppPreferences? _cachedPrefs;

/// Returns a cached [AppPreferences] for tests.
/// Must be called after `SharedPreferences.setMockInitialValues({})`.
Future<AppPreferences> get testAppPreferences async {
  if (_cachedPrefs != null) return _cachedPrefs!;
  _cachedPrefs = await AppPreferences.create();
  return _cachedPrefs!;
}

// ---------------------------------------------------------------------------
// Testable widget helpers
// ---------------------------------------------------------------------------

/// Wraps [child] in a [ProviderScope] and [MaterialApp] with fake providers.
///
/// For tests that need settings functionality, use [testableWidgetAsync] instead.
Widget testableWidget({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(fakeAppConfig()),
      authControllerProvider.overrideWith((ref) => FakeAuthController(ref)),
      ...overrides,
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: child,
    ),
  );
}

/// Async variant of [testableWidget] that also sets up the settings provider.
/// Must be awaited because it creates [AppPreferences] asynchronously.
///
/// Call `SharedPreferences.setMockInitialValues({})` in `setUp` first.
Future<Widget> testableWidgetAsync({
  required Widget child,
  List<Override> overrides = const [],
}) async {
  final prefs = await testAppPreferences;
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(fakeAppConfig()),
      appPreferencesProvider.overrideWithValue(prefs),
      authControllerProvider.overrideWith((ref) => FakeAuthController(ref)),
      settingsControllerProvider.overrideWith(
        (ref) => FakeSettingsController(ref.watch(appPreferencesProvider)),
      ),
      ...overrides,
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: child,
    ),
  );
}
