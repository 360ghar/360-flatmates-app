import 'dart:async';

import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/core/storage/secure_kv_store.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;

import '../../helpers/test_helpers.dart';

/// Starts signed in; everything else is the real controller.
class _SignedInAuthController extends AuthController {
  @override
  Future<void> checkSession() async {
    state = const AuthState(
      status: AuthStatus.authenticated,
      sessionAuthenticated: true,
    );
  }
}

void main() {
  test('a Supabase signedOut event logs the user out (M6)', () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    resetTestAppPreferences();
    final prefs = await testAppPreferences;
    final events = StreamController<AuthChangeEvent>();
    addTearDown(events.close);

    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(fakeAppConfig()),
        appPreferencesProvider.overrideWithValue(prefs),
        secureStoreProvider.overrideWithValue(const SecureKvStore()),
        supabaseAuthEventsProvider.overrideWithValue(events.stream),
        authControllerProvider.overrideWith(_SignedInAuthController.new),
      ],
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(authControllerProvider).isLoggedIn, isTrue);

    events.add(AuthChangeEvent.tokenRefreshed);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(authControllerProvider).isLoggedIn, isTrue);

    events.add(AuthChangeEvent.signedOut);
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
  });
}
