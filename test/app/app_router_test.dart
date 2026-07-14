import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/app/router/app_router.dart';
import 'package:flatmates_app/features/auth/domain/auth_state.dart';
import 'package:flatmates_app/features/bootstrap/domain/bootstrap_models.dart';

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

    test('keeps stale app onboarding gate when no local completion', () {
      expect(
        authenticatedAppReady(
          authStage: AuthStage.appOnboarding,
          hasCompletedOnboardingLocally: false,
        ),
        isFalse,
      );
    });

    test('returns false for unknown stage without local completion', () {
      expect(
        authenticatedAppReady(
          authStage: AuthStage.unknown,
          hasCompletedOnboardingLocally: false,
        ),
        isFalse,
      );
    });

    test('returns false for profileCompletion without local completion', () {
      expect(
        authenticatedAppReady(
          authStage: AuthStage.profileCompletion,
          hasCompletedOnboardingLocally: false,
        ),
        isFalse,
      );
    });
  });

  group('authenticatedIdentifierVerificationRedirect', () {
    test(
      'sends completed authenticated auth routes to discover when profile is complete',
      () {
        const profile = FlatmatesProfileModel(
          id: 1,
          fullName: 'Test User',
          onboardingCompleted: true,
        );
        final redirect = authenticatedIdentifierVerificationRedirect(
          location: '/enter-phone',
          isAuthRoute: true,
          isSplash: false,
          profile: profile,
          hasCompletedOnboardingLocally: true,
        );
        expect(redirect, '/discover');
      },
    );

    test(
      'sends splash to discover when profile is complete and onboarding done',
      () {
        const profile = FlatmatesProfileModel(
          id: 1,
          fullName: 'Test User',
          onboardingCompleted: true,
        );
        final redirect = authenticatedIdentifierVerificationRedirect(
          location: '/splash',
          isAuthRoute: false,
          isSplash: true,
          profile: profile,
          hasCompletedOnboardingLocally: true,
        );
        expect(redirect, '/discover');
      },
    );

    test('keeps profile completion gate when full name is missing', () {
      const profile = FlatmatesProfileModel(
        id: 1,
        fullName: '',
        onboardingCompleted: true,
      );
      final redirect = authenticatedIdentifierVerificationRedirect(
        location: '/discover',
        isAuthRoute: false,
        isSplash: false,
        profile: profile,
        hasCompletedOnboardingLocally: true,
      );
      expect(redirect, '/complete-profile');
    });

    test(
      'returns null when already on complete-profile and name is missing',
      () {
        const profile = FlatmatesProfileModel(
          id: 1,
          fullName: '',
          onboardingCompleted: true,
        );
        final redirect = authenticatedIdentifierVerificationRedirect(
          location: '/complete-profile',
          isAuthRoute: false,
          isSplash: false,
          profile: profile,
          hasCompletedOnboardingLocally: true,
        );
        expect(redirect, isNull);
      },
    );

    test(
      'routes to onboarding when onboarding not completed and on blocked route',
      () {
        const profile = FlatmatesProfileModel(id: 1, fullName: 'Test User');
        final redirect = authenticatedIdentifierVerificationRedirect(
          location: '/swipe',
          isAuthRoute: false,
          isSplash: false,
          profile: profile,
          hasCompletedOnboardingLocally: false,
        );
        expect(redirect, '/onboarding');
      },
    );

    test(
      'returns null when on onboarding page and onboarding not completed',
      () {
        const profile = FlatmatesProfileModel(id: 1, fullName: 'Test User');
        final redirect = authenticatedIdentifierVerificationRedirect(
          location: '/onboarding',
          isAuthRoute: false,
          isSplash: false,
          profile: profile,
          hasCompletedOnboardingLocally: false,
        );
        expect(redirect, isNull);
      },
    );
  });

  group('isOnboardingBlockedRoute', () {
    test('blocks conversations list', () {
      expect(isOnboardingBlockedRoute('/chats'), isTrue);
    });

    test('does not block individual chat threads', () {
      expect(isOnboardingBlockedRoute('/chats/42'), isFalse);
    });

    test('blocks swipe deck', () {
      expect(isOnboardingBlockedRoute('/swipe'), isTrue);
    });

    test('blocks post/new', () {
      expect(isOnboardingBlockedRoute('/post/new'), isTrue);
    });

    test('blocks post', () {
      expect(isOnboardingBlockedRoute('/post'), isTrue);
    });

    test('blocks tab2 (room-poster post hub)', () {
      expect(isOnboardingBlockedRoute('/tab2'), isTrue);
    });

    test('does not block discover', () {
      expect(isOnboardingBlockedRoute('/discover'), isFalse);
    });

    test('does not block profile', () {
      expect(isOnboardingBlockedRoute('/profile'), isFalse);
    });

    test('does not block flat-details deep link', () {
      expect(isOnboardingBlockedRoute('/flat-details/123'), isFalse);
    });

    test('does not block notifications', () {
      expect(isOnboardingBlockedRoute('/notifications'), isFalse);
    });
  });
}
