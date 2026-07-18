import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/app/router/app_router.dart';
import 'package:flatmates_app/features/auth/domain/auth_state.dart';
import 'package:flatmates_app/features/bootstrap/domain/bootstrap_models.dart';

void main() {
  group('shouldForceSplashForBootstrap', () {
    test('forces splash when bootstrap has no value', () {
      expect(
        shouldForceSplashForBootstrap(const AsyncValue<Object?>.loading()),
        isTrue,
      );
      expect(
        shouldForceSplashForBootstrap(
          AsyncValue<Object?>.error(Exception('x'), StackTrace.current),
        ),
        isTrue,
      );
      expect(
        shouldForceSplashForBootstrap(const AsyncValue<Object?>.data(null)),
        isTrue,
      );
    });

    test(
      'does not force splash when previous data is retained while loading',
      () {
        const previous = AsyncValue<Object?>.data('bootstrap');
        final reloading = const AsyncLoading<Object?>().copyWithPrevious(
          previous,
        );
        expect(shouldForceSplashForBootstrap(reloading), isFalse);
        expect(reloading.isLoading, isTrue);
        expect(reloading.valueOrNull, 'bootstrap');
      },
    );

    test('does not force splash when previous data is retained on error', () {
      const previous = AsyncValue<Object?>.data('bootstrap');
      final failed = AsyncError<Object?>(
        Exception('refresh failed'),
        StackTrace.current,
      ).copyWithPrevious(previous);
      expect(shouldForceSplashForBootstrap(failed), isFalse);
      expect(failed.valueOrNull, 'bootstrap');
    });
  });

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

  group('profileCompletionGateRedirect', () {
    test('forces complete-profile when stage is profileCompletion', () {
      expect(
        profileCompletionGateRedirect(
          authStage: AuthStage.profileCompletion,
          isCompleteProfile: false,
          isProfileEdit: false,
        ),
        '/complete-profile',
      );
    });

    test('stays on complete-profile while stage is profileCompletion', () {
      expect(
        profileCompletionGateRedirect(
          authStage: AuthStage.profileCompletion,
          isCompleteProfile: true,
          isProfileEdit: false,
        ),
        isNull,
      );
    });

    test('allows profile edit while stage is profileCompletion', () {
      expect(
        profileCompletionGateRedirect(
          authStage: AuthStage.profileCompletion,
          isCompleteProfile: false,
          isProfileEdit: true,
        ),
        isNull,
      );
    });

    test(
      'exits complete-profile via splash when stage advances to appOnboarding',
      () {
        expect(
          profileCompletionGateRedirect(
            authStage: AuthStage.appOnboarding,
            isCompleteProfile: true,
            isProfileEdit: false,
          ),
          '/splash',
        );
      },
    );

    test('exits complete-profile via splash when stage advances to active', () {
      expect(
        profileCompletionGateRedirect(
          authStage: AuthStage.active,
          isCompleteProfile: true,
          isProfileEdit: false,
        ),
        '/splash',
      );
    });

    test(
      'does not exit complete-profile for identifierVerification fallback',
      () {
        // identifier_verification also uses /complete-profile when full_name
        // is missing. A broad exit would loop complete-profile ↔ splash.
        expect(
          profileCompletionGateRedirect(
            authStage: AuthStage.identifierVerification,
            isCompleteProfile: true,
            isProfileEdit: false,
          ),
          isNull,
        );
      },
    );

    test(
      'does not redirect unrelated routes when stage is not profileCompletion',
      () {
        expect(
          profileCompletionGateRedirect(
            authStage: AuthStage.active,
            isCompleteProfile: false,
            isProfileEdit: false,
          ),
          isNull,
        );
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
