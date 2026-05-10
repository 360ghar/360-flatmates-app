import 'package:freezed_annotation/freezed_annotation.dart';

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
    String? error,
  }) = _OnboardingState;

  double get completionPercentage {
    int completed = 0;
    const int total = 10;

    if (mode != null && mode!.isNotEmpty) completed++;
    if (fullName != null && fullName!.isNotEmpty) completed++;
    if (age != null && age! >= 18) completed++;
    if (city != null && city!.isNotEmpty) completed++;
    if (photoUrls.isNotEmpty) completed++;
    if (lifestyleAnswers.isNotEmpty && lifestyleAnswers.length >= 8) {
      completed++;
    }
    if (budgetMin != null && budgetMax != null) completed++;
    if (moveInTimeline != null && moveInTimeline!.isNotEmpty) completed++;
    if (preferences.isNotEmpty) completed++;
    if (nonNegotiables.isNotEmpty) completed++;

    return ((completed / total) * 100).clamp(0, 100);
  }
}
