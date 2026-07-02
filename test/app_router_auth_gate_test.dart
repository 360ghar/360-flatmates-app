import 'package:flatmates_app/app/router/app_router.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('authenticatedAppReady', () {
    test('treats active backend stage as ready', () {
      expect(
        authenticatedAppReady(
          authStage: AuthStage.active,
          hasCompletedOnboardingLocally: false,
        ),
        isTrue,
      );
    });

    test('treats local onboarding completion as ready during stale gate', () {
      expect(
        authenticatedAppReady(
          authStage: AuthStage.appOnboarding,
          hasCompletedOnboardingLocally: true,
        ),
        isTrue,
      );
    });

    test('keeps stale app onboarding gate when no local completion exists', () {
      expect(
        authenticatedAppReady(
          authStage: AuthStage.appOnboarding,
          hasCompletedOnboardingLocally: false,
        ),
        isFalse,
      );
    });
  });

  group('authenticatedIdentifierVerificationRedirect', () {
    test('sends completed authenticated auth routes to discover', () {
      final profile = fakeBootstrapData().profile;

      final redirect = authenticatedIdentifierVerificationRedirect(
        location: '/login',
        isAuthRoute: true,
        isSplash: false,
        profile: profile,
      );

      expect(redirect, '/discover');
    });

    test('keeps profile completion gate when full name is missing', () {
      final profile = fakeBootstrapData().profile.copyWith(fullName: '');

      final redirect = authenticatedIdentifierVerificationRedirect(
        location: '/login',
        isAuthRoute: true,
        isSplash: false,
        profile: profile,
      );

      expect(redirect, '/profile/edit');
    });

    test('keeps onboarding gate when flatmates onboarding is incomplete', () {
      final profile = fakeBootstrapData().profile.copyWith(
        onboardingCompleted: false,
      );

      final redirect = authenticatedIdentifierVerificationRedirect(
        location: '/login',
        isAuthRoute: true,
        isSplash: false,
        profile: profile,
      );

      expect(redirect, '/onboarding');
    });

    test('allows deep links through after local gates are satisfied', () {
      final profile = fakeBootstrapData().profile;

      final redirect = authenticatedIdentifierVerificationRedirect(
        location: '/chats/123',
        isAuthRoute: false,
        isSplash: false,
        profile: profile,
      );

      expect(redirect, isNull);
    });
  });
}
