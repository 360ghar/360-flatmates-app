import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/features/onboarding/onboarding_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('OnboardingStep.previousStep', () {
    test('splash maps to null', () {
      expect(OnboardingController.previousStep(OnboardingStep.splash), isNull);
    });

    test('modeSelection maps to null', () {
      expect(
        OnboardingController.previousStep(OnboardingStep.modeSelection),
        isNull,
      );
    });

    test('locationSelection maps to modeSelection', () {
      expect(
        OnboardingController.previousStep(OnboardingStep.locationSelection),
        OnboardingStep.modeSelection,
      );
    });

    test('basicInfo maps to locationSelection', () {
      expect(
        OnboardingController.previousStep(OnboardingStep.basicInfo),
        OnboardingStep.locationSelection,
      );
    });

    test('profilePhoto maps to basicInfo', () {
      expect(
        OnboardingController.previousStep(OnboardingStep.profilePhoto),
        OnboardingStep.basicInfo,
      );
    });

    test('lifestyleQuiz maps to profilePhoto', () {
      expect(
        OnboardingController.previousStep(OnboardingStep.lifestyleQuiz),
        OnboardingStep.profilePhoto,
      );
    });

    test('budgetTimeline maps to lifestyleQuiz', () {
      expect(
        OnboardingController.previousStep(OnboardingStep.budgetTimeline),
        OnboardingStep.lifestyleQuiz,
      );
    });

    test('preferences maps to budgetTimeline', () {
      expect(
        OnboardingController.previousStep(OnboardingStep.preferences),
        OnboardingStep.budgetTimeline,
      );
    });

    test('nonNegotiables maps to preferences', () {
      expect(
        OnboardingController.previousStep(OnboardingStep.nonNegotiables),
        OnboardingStep.preferences,
      );
    });
  });

  group('OnboardingState.stepIndex', () {
    test('returns 0 for splash', () {
      const state = OnboardingState();
      expect(state.stepIndex, 0);
    });

    test('returns 1 for modeSelection', () {
      const state = OnboardingState(step: OnboardingStep.modeSelection);
      expect(state.stepIndex, 1);
    });

    test('returns 2 for locationSelection', () {
      const state = OnboardingState(step: OnboardingStep.locationSelection);
      expect(state.stepIndex, 2);
    });

    test('returns 3 for basicInfo', () {
      const state = OnboardingState(step: OnboardingStep.basicInfo);
      expect(state.stepIndex, 3);
    });

    test('returns 4 for profilePhoto', () {
      const state = OnboardingState(step: OnboardingStep.profilePhoto);
      expect(state.stepIndex, 4);
    });

    test('returns 5 for lifestyleQuiz', () {
      const state = OnboardingState(step: OnboardingStep.lifestyleQuiz);
      expect(state.stepIndex, 5);
    });

    test('returns 6 for budgetTimeline', () {
      const state = OnboardingState(step: OnboardingStep.budgetTimeline);
      expect(state.stepIndex, 6);
    });

    test('returns 7 for preferences', () {
      const state = OnboardingState(step: OnboardingStep.preferences);
      expect(state.stepIndex, 7);
    });

    test('returns 8 for nonNegotiables', () {
      const state = OnboardingState(step: OnboardingStep.nonNegotiables);
      expect(state.stepIndex, 8);
    });
  });

  group('OnboardingState.remainingSteps', () {
    test('returns totalInteractiveSteps for splash', () {
      const state = OnboardingState();
      expect(state.remainingSteps, OnboardingState.totalInteractiveSteps);
    });

    test(
      'returns 8 for modeSelection (all steps remaining including current)',
      () {
        const state = OnboardingState(step: OnboardingStep.modeSelection);
        expect(state.remainingSteps, 8);
      },
    );

    test('returns 1 for nonNegotiables (last step)', () {
      const state = OnboardingState(step: OnboardingStep.nonNegotiables);
      expect(state.remainingSteps, 1);
    });

    test('counts correctly for a mid-flow step', () {
      const state = OnboardingState(step: OnboardingStep.basicInfo);
      // stepIndex 3, total 8, remaining = 8 - 3 + 1 = 6
      expect(state.remainingSteps, 6);
    });
  });

  group('OnboardingState.completionPercentage', () {
    test('is 0 for a fresh state', () {
      const state = OnboardingState();
      expect(state.completionPercentage, 0.0);
    });

    test('increases as fields are filled', () {
      const state = OnboardingState(
        mode: 'co_hunter',
        fullName: 'Test',
        age: 25,
        city: 'Bangalore',
      );
      expect(state.completionPercentage, greaterThan(0));
      expect(state.completionPercentage, lessThanOrEqualTo(100));
    });

    test('is 100 when all fields are filled', () {
      const state = OnboardingState(
        mode: 'co_hunter',
        fullName: 'Test',
        age: 25,
        city: 'Bangalore',
        photoUrls: ['url'],
        lifestyleAnswers: {'sleep_schedule': 'flexible'},
        budgetMin: 10000,
        budgetMax: 20000,
        moveInTimeline: 'immediate',
        preferences: {'gender_preference': 'any'},
        nonNegotiables: ['no_smoking'],
      );
      expect(state.completionPercentage, 100.0);
    });
  });
}
