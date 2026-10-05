import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/auth/data/auth_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('FakeAuthController', () {
    test('AuthState.unauthenticated is the default', () {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(fakeAppConfig()),
          authControllerProvider.overrideWith(() => FakeAuthController()),
        ],
      );
      addTearDown(container.dispose);
      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.isLoggedIn, isFalse);
    });

    test('signInWithPassword sets authenticated state', () async {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(fakeAppConfig()),
          authControllerProvider.overrideWith(() => FakeAuthController()),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.signInWithPassword(
        phone: '+919999999999',
        password: 'password123',
      );
      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.phone, '+919999999999');
      expect(state.isLoggedIn, isTrue);
    });

    test('verifyOtp sets authenticatedState', () async {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(fakeAppConfig()),
          authControllerProvider.overrideWith(() => FakeAuthController()),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(authControllerProvider.notifier);
      final result = await notifier.verifyOtp(
        phone: '+919999999999',
        otp: '123456',
      );
      expect(result, isTrue);
      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.phone, '+919999999999');
    });

    test('signOut sets unauthenticated state', () async {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(fakeAppConfig()),
          authControllerProvider.overrideWith(() => FakeAuthController()),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.signInWithPassword(
        phone: '+919999999999',
        password: 'password123',
      );
      expect(container.read(authControllerProvider).isLoggedIn, isTrue);
      await notifier.signOut();
      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.isLoggedIn, isFalse);
    });

    test(
      'checkIdentifierStatus returns phone channel for phone identifiers',
      () async {
        final container = ProviderContainer(
          overrides: [
            appConfigProvider.overrideWithValue(fakeAppConfig()),
            authControllerProvider.overrideWith(() => FakeAuthController()),
          ],
        );
        addTearDown(container.dispose);
        final notifier = container.read(authControllerProvider.notifier);
        final status = await notifier.checkIdentifierStatus('+919999999999');
        expect(status, isNotNull);
        expect(status!.channel, AuthChannel.phone);
      },
    );

    test(
      'checkIdentifierStatus returns email channel for email identifiers',
      () async {
        final container = ProviderContainer(
          overrides: [
            appConfigProvider.overrideWithValue(fakeAppConfig()),
            authControllerProvider.overrideWith(() => FakeAuthController()),
          ],
        );
        addTearDown(container.dispose);
        final notifier = container.read(authControllerProvider.notifier);
        final status = await notifier.checkIdentifierStatus('test@example.com');
        expect(status, isNotNull);
        expect(status!.channel, AuthChannel.email);
      },
    );

    test('signInWithGoogle sets authenticated state', () async {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(fakeAppConfig()),
          authControllerProvider.overrideWith(() => FakeAuthController()),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(authControllerProvider.notifier);
      final result = await notifier.signInWithGoogle();
      expect(result, isTrue);
      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.isLoggedIn, isTrue);
    });

    test('signInWithApple sets authenticated state', () async {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(fakeAppConfig()),
          authControllerProvider.overrideWith(() => FakeAuthController()),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(authControllerProvider.notifier);
      final result = await notifier.signInWithApple();
      expect(result, isTrue);
      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.isLoggedIn, isTrue);
    });
  });

  group('startIdentifierFlow', () {
    Future<(({String? route, bool unverified}), _FlowFake)> run(
      String identifier,
      IdentifierStatus status,
    ) async {
      final fake = _FlowFake(status);
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(fakeAppConfig()),
          authControllerProvider.overrideWith(() => fake),
        ],
      );
      addTearDown(container.dispose);
      final result = await container
          .read(authControllerProvider.notifier)
          .startIdentifierFlow(identifier);
      expect(container.read(pendingPhoneProvider), identifier);
      return (result, fake);
    }

    IdentifierStatus status({
      required bool exists,
      required bool verified,
      required IdentifierNextStep next,
      AuthChannel channel = AuthChannel.phone,
    }) => IdentifierStatus(
      exists: exists,
      verified: verified,
      hasPassword: next == IdentifierNextStep.password,
      channel: channel,
      nextStep: next,
    );

    test('password step opens login and sends no OTP', () async {
      final (result, fake) = await run(
        '+919999999999',
        status(exists: true, verified: true, next: IdentifierNextStep.password),
      );
      expect(result.route, '/login?phone=%2B919999999999');
      expect(result.unverified, isFalse);
      expect(fake.createUser, isNull);
    });

    test('unknown phone signs up through OTP', () async {
      final (result, fake) = await run(
        '+919999999999',
        status(exists: false, verified: false, next: IdentifierNextStep.otp),
      );
      expect(result.route, '/otp?phone=%2B919999999999');
      expect(fake.createUser, isTrue);
    });

    test('verified passwordless phone logs in without creating', () async {
      final (_, fake) = await run(
        '+919999999999',
        status(exists: true, verified: true, next: IdentifierNextStep.otp),
      );
      expect(fake.createUser, isFalse);
    });

    test('unverified email flags the hint and allows creation', () async {
      final (result, fake) = await run(
        'a@b.co',
        status(
          exists: true,
          verified: false,
          next: IdentifierNextStep.otp,
          channel: AuthChannel.email,
        ),
      );
      expect(result.route, '/otp?email=a%40b.co');
      expect(result.unverified, isTrue);
      expect(fake.createUser, isTrue);
    });
  });

  group('AuthState', () {
    test('isLoggedIn is true when sessionAuthenticated is true', () {
      const state = AuthState(
        status: AuthStatus.submitting,
        sessionAuthenticated: true,
      );
      expect(state.isLoggedIn, isTrue);
    });

    test('isLoggedIn is true when status is authenticated', () {
      const state = AuthState(status: AuthStatus.authenticated);
      expect(state.isLoggedIn, isTrue);
    });

    test(
      'isLoggedIn is false when unauthenticated and not sessionAuthenticated',
      () {
        const state = AuthState(status: AuthStatus.unauthenticated);
        expect(state.isLoggedIn, isFalse);
      },
    );
  });

  group('IdentifierStatus', () {
    test('fromJson parses phone channel correctly', () {
      final status = IdentifierStatus.fromJson(const {
        'exists': true,
        'verified': true,
        'has_password': true,
        'channel': 'phone',
        'next_step': 'password',
      });
      expect(status.exists, isTrue);
      expect(status.verified, isTrue);
      expect(status.hasPassword, isTrue);
      expect(status.channel, AuthChannel.phone);
      expect(status.nextStep, IdentifierNextStep.password);
    });

    test('fromJson parses email channel correctly', () {
      final status = IdentifierStatus.fromJson(const {
        'exists': false,
        'verified': false,
        'has_password': false,
        'channel': 'email',
        'next_step': 'otp',
      });
      expect(status.exists, isFalse);
      expect(status.verified, isFalse);
      expect(status.hasPassword, isFalse);
      expect(status.channel, AuthChannel.email);
      expect(status.nextStep, IdentifierNextStep.otp);
    });

    test('fromJson defaults to phone channel when channel is missing', () {
      final status = IdentifierStatus.fromJson(const {});
      expect(status.channel, AuthChannel.phone);
      expect(status.nextStep, IdentifierNextStep.otp);
    });
  });
}

class _FlowFake extends FakeAuthController {
  _FlowFake(this.status);

  final IdentifierStatus status;

  /// The create-user flag of the last OTP request; null when none was sent.
  bool? createUser;

  @override
  Future<IdentifierStatus?> checkIdentifierStatus(String identifier) async =>
      status;

  @override
  Future<void> requestOtp(String phone, {bool shouldCreateUser = false}) async {
    createUser = shouldCreateUser;
  }

  @override
  Future<bool> sendEmailOtp(String email, {bool isSignup = true}) async {
    createUser = isSignup;
    return true;
  }
}
