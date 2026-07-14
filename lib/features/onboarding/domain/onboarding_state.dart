import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/errors/app_failure.dart';

part 'onboarding_state.freezed.dart';

enum OnboardingStep {
  splash,
  modeSelection,
  locationSelection,
  basicInfo,
  profilePhoto,
  lifestyleQuiz,
  budgetTimeline,
  preferences,
  nonNegotiables,
}

@Freezed()
class OnboardingState with _$OnboardingState {
  const OnboardingState._();

  const factory OnboardingState({
    @Default(OnboardingStep.splash) OnboardingStep step,
    String? mode,
    String? fullName,
    int? age,
    String? profession,
    String? city,
    String? locality,
    @Default([]) List<String> photoUrls,
    @Default({}) Map<String, String> lifestyleAnswers,
    double? budgetMin,
    double? budgetMax,
    String? moveInTimeline,
    @Default({}) Map<String, dynamic> preferences,
    @Default([]) List<String> nonNegotiables,
    @Default(false) bool isSubmitting,
    @Default(false) bool isComplete,
    @Default(false) bool isHydrated,
    @Default(false) bool hasError,
    AppFailure? failure,
  }) = _OnboardingState;

  double get completionPercentage {
    int completed = 0;
    const int total = 10;

    if (mode != null && mode!.isNotEmpty) completed++;
    if (fullName != null && fullName!.isNotEmpty) completed++;
    if (age != null && age! >= 18) completed++;
    if (city != null && city!.isNotEmpty) completed++;
    if (photoUrls.isNotEmpty) completed++;
    // The quiz page only advances once every question is answered, and the
    // question count is catalog-driven (not always 8), so credit lifestyle as
    // soon as any answers exist rather than hard-coding a count.
    if (lifestyleAnswers.isNotEmpty) completed++;
    if (budgetMin != null && budgetMax != null) completed++;
    if (moveInTimeline != null && moveInTimeline!.isNotEmpty) completed++;
    if (preferences.isNotEmpty) completed++;
    if (nonNegotiables.isNotEmpty) completed++;

    return ((completed / total) * 100).clamp(0, 100);
  }

  /// 1-based index of the current step within the interactive flow
  /// (excluding the splash carousel). Returns 0 for splash.
  int get stepIndex {
    return switch (step) {
      OnboardingStep.splash => 0,
      OnboardingStep.modeSelection => 1,
      OnboardingStep.locationSelection => 2,
      OnboardingStep.basicInfo => 3,
      OnboardingStep.profilePhoto => 4,
      OnboardingStep.lifestyleQuiz => 5,
      OnboardingStep.budgetTimeline => 6,
      OnboardingStep.preferences => 7,
      OnboardingStep.nonNegotiables => 8,
    };
  }

  /// Total number of interactive steps (excluding splash).
  static const int totalInteractiveSteps = 8;

  /// Number of interactive steps remaining, including the current one.
  int get remainingSteps {
    if (step == OnboardingStep.splash) return totalInteractiveSteps;
    return totalInteractiveSteps - stepIndex + 1;
  }
}
