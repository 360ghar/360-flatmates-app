import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bootstrap/bootstrap_controller.dart';
import '../profile/profile_repository.dart';

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController(this._ref) : super(const OnboardingState());

  final Ref _ref;

  Future<void> setMode(String mode) async {
    state = state.copyWith(mode: mode, step: OnboardingStep.basicInfo);
  }

  Future<void> setBasicInfo(Map<String, dynamic> data) async {
    state = state.copyWith(
      fullName: data['full_name'] as String?,
      age: data['age'] as int?,
      profession: data['profession'] as String?,
      city: data['city'] as String?,
      locality: data['locality'] as String?,
      step: OnboardingStep.profilePhoto,
    );
  }

  Future<void> setPhotoUrls(List<String> urls) async {
    state = state.copyWith(photoUrls: urls, step: OnboardingStep.lifestyleQuiz);
  }

  Future<void> setLifestyleAnswers(Map<String, String> answers) async {
    state = state.copyWith(lifestyleAnswers: answers, step: OnboardingStep.budgetTimeline);
  }

  Future<void> setBudgetTimeline(Map<String, dynamic> data) async {
    state = state.copyWith(
      budgetMin: data['budget_min'] as double?,
      budgetMax: data['budget_max'] as double?,
      moveInTimeline: data['move_in_timeline'] as String?,
      step: OnboardingStep.nonNegotiables,
    );
  }

  Future<void> submitNonNegotiables(List<String> nonNegotiables) async {
    state = state.copyWith(nonNegotiables: nonNegotiables, isSubmitting: true);

    try {
      final payload = <String, dynamic>{
        'mode': state.mode,
        'full_name': state.fullName,
        'age': state.age,
        'city': state.city,
        'locality': state.locality,
        'budget_min': state.budgetMin,
        'budget_max': state.budgetMax,
        'move_in_timeline': state.moveInTimeline,
        'onboarding_completed': true,
        'preferences': {
          'profession': state.profession,
          'photo_urls': state.photoUrls,
          'non_negotiables': state.nonNegotiables,
          ...state.lifestyleAnswers,
        },
      };

      payload.addAll(state.lifestyleAnswers);

      if (state.photoUrls.isNotEmpty) {
        payload['profile_image_url'] = state.photoUrls.first;
      }

      await _ref.read(profileRepositoryProvider).updateProfile(payload: payload);
      await _ref.read(bootstrapControllerProvider.notifier).load();
      state = state.copyWith(isSubmitting: false, isComplete: true);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }
}

enum OnboardingStep {
  splash,
  modeSelection,
  basicInfo,
  profilePhoto,
  lifestyleQuiz,
  budgetTimeline,
  nonNegotiables,
}

class OnboardingState {
  const OnboardingState({
    this.step = OnboardingStep.splash,
    this.mode,
    this.fullName,
    this.age,
    this.profession,
    this.city,
    this.locality,
    this.photoUrls = const [],
    this.lifestyleAnswers = const {},
    this.budgetMin,
    this.budgetMax,
    this.moveInTimeline,
    this.nonNegotiables = const [],
    this.isSubmitting = false,
    this.isComplete = false,
    this.error,
  });

  final OnboardingStep step;
  final String? mode;
  final String? fullName;
  final int? age;
  final String? profession;
  final String? city;
  final String? locality;
  final List<String> photoUrls;
  final Map<String, String> lifestyleAnswers;
  final double? budgetMin;
  final double? budgetMax;
  final String? moveInTimeline;
  final List<String> nonNegotiables;
  final bool isSubmitting;
  final bool isComplete;
  final String? error;

  OnboardingState copyWith({
    OnboardingStep? step,
    String? mode,
    String? fullName,
    int? age,
    String? profession,
    String? city,
    String? locality,
    List<String>? photoUrls,
    Map<String, String>? lifestyleAnswers,
    double? budgetMin,
    double? budgetMax,
    String? moveInTimeline,
    List<String>? nonNegotiables,
    bool? isSubmitting,
    bool? isComplete,
    String? error,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      mode: mode ?? this.mode,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      profession: profession ?? this.profession,
      city: city ?? this.city,
      locality: locality ?? this.locality,
      photoUrls: photoUrls ?? this.photoUrls,
      lifestyleAnswers: lifestyleAnswers ?? this.lifestyleAnswers,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      moveInTimeline: moveInTimeline ?? this.moveInTimeline,
      nonNegotiables: nonNegotiables ?? this.nonNegotiables,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isComplete: isComplete ?? this.isComplete,
      error: error ?? this.error,
    );
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>(
      (ref) => OnboardingController(ref),
    );
