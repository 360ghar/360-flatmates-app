import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/error_presenter.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../profile/profile_repository.dart';
import 'domain/onboarding_state.dart';

export 'domain/onboarding_state.dart';

class OnboardingController extends Notifier<OnboardingState> {
  static const String _prefsKey = 'onboarding_state';

  @override
  OnboardingState build() {
    _loadSavedState();
    return const OnboardingState();
  }

  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_prefsKey);
      if (savedJson != null) {
        final savedData = jsonDecode(savedJson) as Map<String, dynamic>;
        final savedStep = OnboardingStep.values.firstWhere(
          (e) => e.name == savedData['step'],
          orElse: () => OnboardingStep.splash,
        );

        if (!(savedData['isComplete'] as bool? ?? false)) {
          state = OnboardingState(
            step: savedStep,
            mode: savedData['mode'] as String?,
            fullName: savedData['full_name'] as String?,
            age: savedData['age'] as int?,
            profession: savedData['profession'] as String?,
            city: savedData['city'] as String?,
            locality: savedData['locality'] as String?,
            photoUrls:
                (savedData['photo_urls'] as List?)?.cast<String>() ?? const [],
            lifestyleAnswers: Map<String, String>.from(
              savedData['lifestyle_answers'] as Map? ?? const {},
            ),
            budgetMin: (savedData['budget_min'] as num?)?.toDouble(),
            budgetMax: (savedData['budget_max'] as num?)?.toDouble(),
            moveInTimeline: savedData['move_in_timeline'] as String?,
            preferences: Map<String, dynamic>.from(
              savedData['preferences'] as Map? ?? const {},
            ),
            nonNegotiables:
                (savedData['non_negotiables'] as List?)?.cast<String>() ??
                const [],
          );
        }
      }
    } catch (e, st) {
      debugPrint('[OnboardingController] _loadSavedState error: $e\n$st');
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'step': state.step.name,
        'mode': state.mode,
        'full_name': state.fullName,
        'age': state.age,
        'profession': state.profession,
        'city': state.city,
        'locality': state.locality,
        'photo_urls': state.photoUrls,
        'lifestyle_answers': state.lifestyleAnswers,
        'budget_min': state.budgetMin,
        'budget_max': state.budgetMax,
        'move_in_timeline': state.moveInTimeline,
        'preferences': state.preferences,
        'non_negotiables': state.nonNegotiables,
        'isComplete': state.isComplete,
      };
      await prefs.setString(_prefsKey, jsonEncode(data));
    } catch (e) {
      // Ignore save errors
    }
  }

  Future<void> _clearSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> setMode(String mode) async {
    state = state.copyWith(mode: mode, step: OnboardingStep.locationSelection);
    await _saveState();
  }

  Future<void> completeSplash() async {
    state = state.copyWith(step: OnboardingStep.modeSelection);
    await _saveState();
  }

  Future<void> setLocation(Map<String, String?> data) async {
    state = state.copyWith(
      city: data['city'],
      locality: data['locality'],
      step: OnboardingStep.basicInfo,
    );
    await _saveState();
  }

  Future<void> setBasicInfo(Map<String, dynamic> data) async {
    state = state.copyWith(
      fullName: data['full_name'] as String?,
      age: data['age'] as int?,
      profession: data['profession'] as String?,
      city: data['city'] as String? ?? state.city,
      locality: data['locality'] as String? ?? state.locality,
      step: OnboardingStep.profilePhoto,
    );
    await _saveState();
  }

  Future<void> setPhotoUrls(List<String> urls) async {
    state = state.copyWith(photoUrls: urls, step: OnboardingStep.lifestyleQuiz);
    await _saveState();
  }

  Future<void> setLifestyleAnswers(Map<String, String> answers) async {
    state = state.copyWith(
      lifestyleAnswers: answers,
      step: OnboardingStep.budgetTimeline,
    );
    await _saveState();
  }

  Future<void> setBudgetTimeline(Map<String, dynamic> data) async {
    final budgetMin = data['budget_min'] as double?;
    final budgetMax = data['budget_max'] as double?;
    if (budgetMin != null && budgetMax != null && budgetMin > budgetMax) {
      return;
    }
    state = state.copyWith(
      budgetMin: budgetMin,
      budgetMax: budgetMax,
      moveInTimeline: data['move_in_timeline'] as String?,
      step: OnboardingStep.preferences,
    );
    await _saveState();
  }

  Future<void> setPreferences(Map<String, dynamic> data) async {
    state = state.copyWith(
      preferences: data,
      step: OnboardingStep.nonNegotiables,
    );
    await _saveState();
  }

  Future<void> submitNonNegotiables(List<String> nonNegotiables) async {
    if (state.isSubmitting) return;
    state = state.copyWith(nonNegotiables: nonNegotiables, isSubmitting: true);
    await _saveState();

    try {
      final lifestyleAnswers = _normalizeLifestyleAnswers(
        state.lifestyleAnswers,
      );
      final preferences = _normalizePreferences(state.preferences);
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
          ...lifestyleAnswers,
          ...preferences,
        },
      };

      if (state.photoUrls.isNotEmpty) {
        payload['profile_image_url'] = state.photoUrls.first;
      }

      await ref.read(profileRepositoryProvider).updateProfile(payload: payload);
      await ref.read(bootstrapControllerProvider.notifier).load();
      state = state.copyWith(isSubmitting: false, isComplete: true);
      await _clearSavedState();
    } on DioException catch (e, st) {
      final failure = ErrorPresenter.fromDio(e, st);
      state = state.copyWith(isSubmitting: false, error: failure.label);
      await _saveState();
    } catch (e, st) {
      debugPrint('[OnboardingController] submitNonNegotiables error: $e\n$st');
      state = state.copyWith(
        isSubmitting: false,
        error: 'Failed to complete onboarding. Please try again.',
      );
      await _saveState();
    }
  }
}

Map<String, String> _normalizeLifestyleAnswers(Map<String, String> answers) {
  return answers.map((key, value) {
    return MapEntry(key, _normalizeFlatmateValue(key, value));
  });
}

Map<String, dynamic> _normalizePreferences(Map<String, dynamic> preferences) {
  return preferences.map((key, value) {
    if (value is! String) return MapEntry(key, value);
    final normalizedKey = key == 'preferred_gender' ? 'gender_preference' : key;
    return MapEntry(
      normalizedKey,
      _normalizeFlatmateValue(normalizedKey, value),
    );
  });
}

String _normalizeFlatmateValue(String key, String value) {
  return switch ((key, value)) {
    ('food_habits', 'veg') => 'vegetarian',
    ('food_habits', 'non_veg') => 'non_vegetarian',
    ('gender_preference', 'no_preference') => 'any',
    ('gender_preference', 'male_only') => 'male',
    ('gender_preference', 'female_only') => 'female',
    ('pets', 'yes') => 'have_pets',
    ('pets', 'no') => 'no_pets',
    ('smoking', 'no') => 'neither',
    ('smoking', 'yes') => 'smoke_outside',
    _ => value,
  };
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );
