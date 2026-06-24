import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flatmates_app/core/config/app_config.dart';
import 'package:flatmates_app/core/network/auth_token_provider.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/core/storage/app_preferences.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/auth/data/auth_repository.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/settings/settings_controller.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

/// A minimal [AppConfig] for tests.
AppConfig fakeAppConfig() => const AppConfig(
  environment: AppEnvironment.dev,
  apiBaseUrl: 'https://api.test.example.com',
  supabaseUrl: 'https://test.supabase.co',
  supabasePublishableKey: 'test-anon-key',
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

// ---------------------------------------------------------------------------
// Fake controllers
// ---------------------------------------------------------------------------

/// A fake [AuthController] that overrides every method to avoid Supabase.
class FakeAuthController extends AuthController {
  @override
  AuthState build() {
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  Future<void> checkSession() async {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  Future<void> requestOtp(String phone, {bool shouldCreateUser = false}) async {
    state = AuthState(status: AuthStatus.unauthenticated, phone: phone);
  }

  @override
  Future<bool> verifyOtp({required String phone, required String otp}) async {
    state = AuthState(status: AuthStatus.authenticated, phone: phone);
    return true;
  }

  @override
  Future<bool> signInWithPassword({
    required String phone,
    required String password,
  }) async {
    state = AuthState(status: AuthStatus.authenticated, phone: phone);
    return true;
  }

  @override
  Future<IdentifierStatus?> checkIdentifierStatus(String identifier) async {
    return IdentifierStatus(
      exists: false,
      verified: false,
      hasPassword: false,
      channel: identifier.contains('@') ? AuthChannel.email : AuthChannel.phone,
      nextStep: IdentifierNextStep.otp,
    );
  }

  @override
  Future<bool> signInWithGoogle() async {
    state = const AuthState(status: AuthStatus.authenticated);
    return true;
  }

  @override
  Future<bool> signInWithApple() async {
    state = const AuthState(status: AuthStatus.authenticated);
    return true;
  }

  @override
  Future<void> signOut() async {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

/// A fake [SettingsController] that overrides load to avoid disk I/O.
class FakeSettingsController extends SettingsController {
  FakeSettingsController();

  @override
  SettingsState build() {
    return const SettingsState().copyWith(loaded: true);
  }

  @override
  Future<void> load() async {
    state = state.copyWith(loaded: true);
  }
}

BootstrapData fakeBootstrapData() => const BootstrapData(
  profile: FlatmatesProfileModel(
    id: 1,
    fullName: 'Test User',
    phone: '+919999999999',
    email: 'test@example.com',
    mode: 'co_hunter',
    profileStatus: 'active',
    onboardingCompleted: true,
    age: 25,
    profession: 'Engineer',
    city: 'Bangalore',
    state: 'Karnataka',
    locality: 'Koramangala',
  ),
  catalogs: [
    CatalogEntryModel(
      key: 'flatmates_modes',
      version: 1,
      payload: {
        'items': [
          {
            'id': 'co_hunter',
            'label': 'Find a Flat / Flatmate',
            'description': 'I want to find a place or a flatmate to stay with',
          },
          {
            'id': 'room_poster',
            'label': 'List My Flat / Find Flatmate',
            'description': 'I want to list my flat or find a flatmate',
          },
          {
            'id': 'open_to_both',
            'label': 'Open to Both',
            'description': 'Flexible to find or list',
          },
        ],
      },
    ),
    CatalogEntryModel(
      key: 'flatmates_popular_cities',
      version: 1,
      payload: {
        'items': [
          {
            'id': 'bangalore',
            'label': 'Bangalore',
            'latitude': 12.9716,
            'longitude': 77.5946,
            'state': 'Karnataka',
          },
          {
            'id': 'gurgaon',
            'label': 'Gurgaon',
            'latitude': 28.4595,
            'longitude': 77.0266,
            'state': 'Haryana',
          },
          {
            'id': 'hyderabad',
            'label': 'Hyderabad',
            'coming_soon': true,
            'latitude': 17.385,
            'longitude': 78.4867,
            'state': 'Telangana',
          },
        ],
      },
    ),
  ],
);

class FakeBootstrapController extends BootstrapController {
  FakeBootstrapController() {
    state = AsyncValue.data(fakeBootstrapData());
  }

  @override
  Future<BootstrapData?> build() async {
    state = AsyncValue.data(fakeBootstrapData());
    return fakeBootstrapData();
  }

  @override
  Future<void> refresh() async {
    state = AsyncValue.data(fakeBootstrapData());
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

/// Resets the cached [AppPreferences] so the next call to
/// [testAppPreferences] creates a fresh instance.
/// Call this in `tearDown` or between tests that mutate preferences.
void resetTestAppPreferences() {
  _cachedPrefs = null;
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
      authControllerProvider.overrideWith(() => FakeAuthController()),
      bootstrapControllerProvider.overrideWith(() => FakeBootstrapController()),
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
      authControllerProvider.overrideWith(() => FakeAuthController()),
      bootstrapControllerProvider.overrideWith(() => FakeBootstrapController()),
      settingsControllerProvider.overrideWith(() => FakeSettingsController()),
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
