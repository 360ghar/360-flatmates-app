import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/core/storage/app_preferences.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/onboarding/mode_selection_page.dart';
import 'package:flatmates_app/features/onboarding/basic_info_page.dart';
import 'package:flatmates_app/features/onboarding/onboarding_controller.dart';
import 'package:flatmates_app/features/profile/profile_repository.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_ui.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('OnboardingController', () {
    test('completing splash moves a new user to mode selection', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await testAppPreferences;
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final controller = container.read(onboardingControllerProvider.notifier);
      await controller.completeSplash();

      final state = container.read(onboardingControllerProvider);
      expect(state.step, OnboardingStep.modeSelection);
      expect(state.mode, isNull);
    });

    test('previousStep maps the flow backwards and stops at modeSelection', () {
      expect(
        OnboardingController.previousStep(OnboardingStep.modeSelection),
        isNull,
      );
      expect(OnboardingController.previousStep(OnboardingStep.splash), isNull);
      expect(
        OnboardingController.previousStep(OnboardingStep.basicInfo),
        OnboardingStep.locationSelection,
      );
      expect(
        OnboardingController.previousStep(OnboardingStep.nonNegotiables),
        OnboardingStep.preferences,
      );
    });

    test(
      'goBack steps backwards while preserving collected draft data',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await testAppPreferences;
        final container = ProviderContainer(
          overrides: [appPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        final controller = container.read(
          onboardingControllerProvider.notifier,
        );
        await controller.setMode('co_hunter');
        await controller.setLocation({'city': 'Delhi', 'locality': null});
        await controller.setBasicInfo({
          'full_name': 'Jane Doe',
          'age': 25,
          'profession': 'Designer',
          'city': 'Delhi',
        });

        expect(
          container.read(onboardingControllerProvider).step,
          OnboardingStep.profilePhoto,
        );

        // Step back to basic info, then to location — data must survive.
        final moved = await controller.goBack();
        expect(moved, isTrue);
        expect(
          container.read(onboardingControllerProvider).step,
          OnboardingStep.basicInfo,
        );
        expect(
          container.read(onboardingControllerProvider).fullName,
          'Jane Doe',
        );

        await controller.goBack();
        expect(
          container.read(onboardingControllerProvider).step,
          OnboardingStep.locationSelection,
        );
        expect(container.read(onboardingControllerProvider).city, 'Delhi');
      },
    );

    test(
      'goBack at mode selection is a no-op and reports no transition',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await testAppPreferences;
        final container = ProviderContainer(
          overrides: [appPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        final controller = container.read(
          onboardingControllerProvider.notifier,
        );
        await controller.completeSplash();
        expect(controller.canGoBack, isFalse);

        final moved = await controller.goBack();
        expect(moved, isFalse);
        expect(
          container.read(onboardingControllerProvider).step,
          OnboardingStep.modeSelection,
        );
      },
    );

    test(
      'a saved in-progress draft is restored on a fresh controller',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await testAppPreferences;
        final container = ProviderContainer(
          overrides: [appPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        final controller = container.read(
          onboardingControllerProvider.notifier,
        );
        await controller.setMode('room_poster');
        await controller.setLocation({'city': 'Mumbai', 'locality': null});

        // Simulate an app restart: a brand new container reading the same prefs.
        final restarted = ProviderContainer(
          overrides: [appPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(restarted.dispose);

        final restored = restarted.read(onboardingControllerProvider);
        expect(restored.step, OnboardingStep.basicInfo);
        expect(restored.mode, 'room_poster');
        expect(restored.city, 'Mumbai');
        expect(restored.isHydrated, isTrue);
      },
    );

    test(
      'submit completes only after bootstrap confirms onboarding is complete',
      () async {
        SharedPreferences.setMockInitialValues({});
        resetTestAppPreferences();
        final prefs = await testAppPreferences;
        final repository = _FakeProfileRepository();
        final container = ProviderContainer(
          overrides: [
            appPreferencesProvider.overrideWithValue(prefs),
            profileRepositoryProvider.overrideWithValue(repository),
            authControllerProvider.overrideWith(_OnboardingAuthController.new),
            bootstrapControllerProvider.overrideWith(
              _CompletedOnboardingBootstrapController.new,
            ),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(
          onboardingControllerProvider.notifier,
        );
        await _fillOnboardingDraft(controller);
        await controller.submitNonNegotiables(['quiet_hours']);

        final state = container.read(onboardingControllerProvider);
        expect(state.isComplete, isTrue);
        expect(state.hasError, isFalse);
        expect(repository.updateCalls, 1);
        expect(repository.completeCalls, 1);
        expect(
          container.read(authControllerProvider).authStage,
          AuthStage.active,
        );
      },
    );

    test(
      'submit completes with local override when refreshed gate is stale',
      () async {
        SharedPreferences.setMockInitialValues({});
        resetTestAppPreferences();
        final prefs = await testAppPreferences;
        final repository = _FakeProfileRepository();
        final container = ProviderContainer(
          overrides: [
            appPreferencesProvider.overrideWithValue(prefs),
            profileRepositoryProvider.overrideWithValue(repository),
            authControllerProvider.overrideWith(_OnboardingAuthController.new),
            bootstrapControllerProvider.overrideWith(
              _StaleOnboardingBootstrapController.new,
            ),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(
          onboardingControllerProvider.notifier,
        );
        await _fillOnboardingDraft(controller);
        await controller.submitNonNegotiables(['quiet_hours']);

        final state = container.read(onboardingControllerProvider);
        expect(state.isSubmitting, isFalse);
        expect(state.isComplete, isTrue);
        expect(state.hasError, isFalse);
        expect(
          container.read(flatmatesOnboardingCompletedOverrideProvider),
          isTrue,
        );
        expect(
          prefs.getString(PrefKeys.flatmatesOnboardingCompletedUserId),
          fakeBootstrapData().profile.id.toString(),
        );
        expect(repository.updateCalls, 1);
        expect(repository.completeCalls, 1);
      },
    );
  });

  group('ModeSelectionPage', () {
    testWidgets('renders exactly three mode options', (tester) async {
      await tester.pumpWidget(
        testableWidget(child: ModeSelectionPage(onModeSelected: (_) {})),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mode_room_poster')), findsOneWidget);
      expect(find.byKey(const Key('mode_co_hunter')), findsOneWidget);
      expect(find.byKey(const Key('mode_open_to_both')), findsOneWidget);
    });

    testWidgets('selecting a mode and pressing continue calls onModeSelected', (
      tester,
    ) async {
      String? selectedMode;
      await tester.pumpWidget(
        testableWidget(
          child: ModeSelectionPage(
            onModeSelected: (mode) => selectedMode = mode,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select a mode card
      await tester.tap(find.byKey(const Key('mode_co_hunter')));
      await tester.pumpAndSettle();

      // Continue button should now be enabled — tap it
      await tester.tap(find.byKey(const Key('mode_continue')));
      expect(selectedMode, 'co_hunter');
    });
  });

  group('BasicInfoPage', () {
    // BasicInfoPage now hydrates from the onboarding draft in initState, which
    // builds OnboardingController and therefore needs AppPreferences overridden.
    late List<Override> overrides;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      resetTestAppPreferences();
      final prefs = await testAppPreferences;
      overrides = [appPreferencesProvider.overrideWithValue(prefs)];
    });

    testWidgets('next button is disabled when fields are empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        testableWidget(
          overrides: overrides,
          child: BasicInfoPage(onNext: (_) {}),
        ),
      );
      await tester.pump();

      // Scroll to bottom to ensure the button is visible in ListView
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pump();

      final keyFinder = find.byKey(const Key('onboarding_basic_info_next'));
      expect(keyFinder, findsOneWidget);
      final button = tester.widget<FlatmatesButton>(keyFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets('next button is disabled when age is under 18', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          overrides: overrides,
          child: BasicInfoPage(onNext: (_) {}),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('onboarding_name')),
        'John Doe',
      );
      await tester.enterText(find.byKey(const Key('onboarding_age')), '17');
      await tester.enterText(
        find.byKey(const Key('onboarding_profession')),
        'Engineer',
      );
      await tester.enterText(find.byKey(const Key('onboarding_city')), 'Delhi');
      await tester.pump();

      // Scroll to bottom
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pump();

      final button = tester.widget<FlatmatesButton>(
        find.byKey(const Key('onboarding_basic_info_next')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('next button is enabled when all fields valid and age >= 18', (
      tester,
    ) async {
      await tester.pumpWidget(
        testableWidget(
          overrides: overrides,
          child: BasicInfoPage(onNext: (_) {}),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('onboarding_name')),
        'Jane Doe',
      );
      await tester.enterText(find.byKey(const Key('onboarding_age')), '25');
      await tester.enterText(
        find.byKey(const Key('onboarding_profession')),
        'Designer',
      );
      await tester.enterText(
        find.byKey(const Key('onboarding_city')),
        'Mumbai',
      );
      await tester.pump();

      // Scroll to bottom
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pump();

      final button = tester.widget<FlatmatesButton>(
        find.byKey(const Key('onboarding_basic_info_next')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('age of exactly 18 is accepted', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          overrides: overrides,
          child: BasicInfoPage(onNext: (_) {}),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('onboarding_name')),
        'Test User',
      );
      await tester.enterText(find.byKey(const Key('onboarding_age')), '18');
      await tester.enterText(
        find.byKey(const Key('onboarding_profession')),
        'Student',
      );
      await tester.enterText(
        find.byKey(const Key('onboarding_city')),
        'Bangalore',
      );
      await tester.pump();

      // Scroll to bottom
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pump();

      final button = tester.widget<FlatmatesButton>(
        find.byKey(const Key('onboarding_basic_info_next')),
      );
      expect(button.onPressed, isNotNull);
    });
  });
}

Future<void> _fillOnboardingDraft(OnboardingController controller) async {
  await controller.setMode('co_hunter');
  await controller.setLocation({
    'city': 'Bangalore',
    'locality': 'Koramangala',
  });
  await controller.setBasicInfo({
    'full_name': 'Test User',
    'age': 25,
    'profession': 'Engineer',
    'city': 'Bangalore',
    'locality': 'Koramangala',
  });
  await controller.setPhotoUrls(['https://example.com/photo.jpg']);
  await controller.setLifestyleAnswers({
    'sleep_schedule': 'early_bird',
    'cleanliness': 'very_clean',
  });
  await controller.setBudgetTimeline({
    'budget_min': 10000.0,
    'budget_max': 20000.0,
    'move_in_timeline': 'within_month',
  });
  await controller.setPreferences({'gender_preference': 'any'});
}

class _FakeProfileRepository implements ProfileRepository {
  var updateCalls = 0;
  var completeCalls = 0;

  @override
  Future<FlatmatesProfileModel> updateProfile({
    required Map<String, dynamic> payload,
  }) async {
    updateCalls += 1;
    return fakeBootstrapData().profile.copyWith(
      fullName: payload['full_name'] as String?,
      onboardingCompleted: false,
    );
  }

  @override
  Future<FlatmatesProfileModel> fetchProfile() async {
    return fakeBootstrapData().profile;
  }

  @override
  Future<void> completeFlatmatesOnboarding() async {
    completeCalls += 1;
  }
}

class _OnboardingAuthController extends FakeAuthController {
  @override
  AuthState build() {
    return const AuthState(
      status: AuthStatus.authenticated,
      authStage: AuthStage.appOnboarding,
      sessionAuthenticated: true,
    );
  }
}

class _CompletedOnboardingBootstrapController extends BootstrapController {
  @override
  Future<BootstrapData?> build() async {
    return fakeBootstrapData();
  }

  @override
  Future<void> refresh() async {
    ref.read(authControllerProvider.notifier).updateGateStage(AuthStage.active);
    state = AsyncValue.data(fakeBootstrapData());
  }
}

class _StaleOnboardingBootstrapController extends BootstrapController {
  @override
  Future<BootstrapData?> build() async {
    return _incompleteBootstrapData();
  }

  @override
  Future<void> refresh() async {
    ref
        .read(authControllerProvider.notifier)
        .updateGateStage(AuthStage.appOnboarding);
    state = AsyncValue.data(_incompleteBootstrapData());
  }

  BootstrapData _incompleteBootstrapData() {
    final data = fakeBootstrapData();
    return data.copyWith(
      profile: data.profile.copyWith(onboardingCompleted: false),
    );
  }
}
