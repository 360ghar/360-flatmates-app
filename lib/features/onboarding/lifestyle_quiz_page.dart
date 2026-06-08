import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/components.dart';
import 'onboarding_controller.dart';

class LifestyleQuizPage extends ConsumerStatefulWidget {
  const LifestyleQuizPage({required this.onComplete, super.key});

  final void Function(Map<String, String> answers) onComplete;

  @override
  ConsumerState<LifestyleQuizPage> createState() => _LifestyleQuizPageState();
}

class _LifestyleQuizPageState extends ConsumerState<LifestyleQuizPage> {
  final _answers = <String, String>{};

  @override
  void initState() {
    super.initState();
    final controllerState = ref.read(onboardingControllerProvider);
    _answers.addAll(controllerState.lifestyleAnswers);
  }

  /// Hardcoded fallback questions used when the backend catalog is unavailable.
  static final _fallbackQuestions = [
    _QuizQuestion(
      key: 'sleep_schedule',
      emoji: '🌙',
      title: (l) => l.quizSleepSchedule,
      options: [
        _QuizOption(key: 'early_bird', label: (l) => l.quizEarlyBird),
        _QuizOption(key: 'flexible', label: (l) => l.quizFlexible),
        _QuizOption(key: 'night_owl', label: (l) => l.quizNightOwl),
      ],
    ),
    _QuizQuestion(
      key: 'cleanliness',
      emoji: '🧹',
      title: (l) => l.quizCleanliness,
      options: [
        _QuizOption(key: 'minimal', label: (l) => l.quizCleanMinimal),
        _QuizOption(key: 'tidy', label: (l) => l.quizCleanTidy),
        _QuizOption(key: 'spotless', label: (l) => l.quizCleanSpotless),
      ],
    ),
    _QuizQuestion(
      key: 'food_habits',
      emoji: '🍽️',
      title: (l) => l.quizFoodHabits,
      options: [
        _QuizOption(key: 'vegetarian', label: (l) => l.quizVegetarian),
        _QuizOption(key: 'vegan', label: (l) => l.quizVegan),
        _QuizOption(key: 'non_vegetarian', label: (l) => l.quizNonVegetarian),
        _QuizOption(key: 'eggetarian', label: (l) => l.quizEggetarian),
        _QuizOption(key: 'no_preference', label: (l) => l.quizNoFoodPref),
      ],
    ),
    _QuizQuestion(
      key: 'smoking_drinking',
      emoji: '🚬',
      title: (l) => l.quizSmokingDrinking,
      options: [
        _QuizOption(key: 'neither', label: (l) => l.quizNeither),
        _QuizOption(key: 'smoke_outside', label: (l) => l.quizSmokeOutside),
        _QuizOption(
          key: 'drink_occasionally',
          label: (l) => l.quizDrinkOccasionally,
        ),
        _QuizOption(key: 'both_fine', label: (l) => l.quizBothFine),
      ],
    ),
    _QuizQuestion(
      key: 'guests_policy',
      emoji: '👥',
      title: (l) => l.quizGuestsPolicy,
      options: [
        _QuizOption(key: 'no_overnight_guests', label: (l) => l.quizNoGuests),
        _QuizOption(key: 'occasional_ok', label: (l) => l.quizOccasionalGuests),
        _QuizOption(key: 'open_house', label: (l) => l.quizOpenHouse),
      ],
    ),
    _QuizQuestion(
      key: 'parties_at_home',
      emoji: '🎉',
      title: (l) => l.quizParties,
      options: [
        _QuizOption(key: 'never', label: (l) => l.quizPartiesNever),
        _QuizOption(
          key: 'occasional_weekends',
          label: (l) => l.quizPartiesWeekends,
        ),
        _QuizOption(key: 'party_friendly', label: (l) => l.quizPartyFriendly),
      ],
    ),
    _QuizQuestion(
      key: 'work_style',
      emoji: '💻',
      title: (l) => l.quizWorkStyle,
      options: [
        _QuizOption(key: 'wfh', label: (l) => l.quizWfh),
        _QuizOption(key: 'office', label: (l) => l.quizOffice),
        _QuizOption(key: 'hybrid', label: (l) => l.quizHybrid),
      ],
    ),
    _QuizQuestion(
      key: 'pets',
      emoji: '🐾',
      title: (l) => l.quizPets,
      options: [
        _QuizOption(key: 'no_pets', label: (l) => l.quizNoPets),
        _QuizOption(key: 'have_pets', label: (l) => l.quizHavePets),
        _QuizOption(key: 'pet_friendly', label: (l) => l.quizPetFriendly),
      ],
    ),
  ];

  /// Resolve quiz questions: try backend catalog first, fall back to hardcoded.
  List<_QuizQuestion> get _questions {
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final catalogQuestions = bootstrap?.catalogOptions(
      'flatmates_lifestyle_quiz',
    );
    if (catalogQuestions != null && catalogQuestions.isNotEmpty) {
      return catalogQuestions.map((q) {
        final rawOptions = q.meta['options'];
        final optionList = <_QuizOption>[];
        if (rawOptions is List) {
          for (final raw in rawOptions) {
            if (raw is Map) {
              final map = Map<String, dynamic>.from(raw);
              final id = (map['id'] ?? map['value'] ?? map['key'] ?? '')
                  .toString()
                  .trim();
              final label = (map['label'] ?? map['name'] ?? id)
                  .toString()
                  .trim();
              if (id.isNotEmpty && label.isNotEmpty) {
                optionList.add(_QuizOption(key: id, label: (_) => label));
              }
            }
          }
        }
        if (optionList.isEmpty) {
          optionList.add(_QuizOption(key: q.id, label: (_) => q.label));
        }
        return _QuizQuestion(
          key: q.id,
          emoji: q.meta['emoji']?.toString() ?? '❓',
          title: (_) => q.label,
          options: optionList,
        );
      }).toList();
    }
    return _fallbackQuestions;
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final questions = _questions;
    final answeredCount = _answers.length;
    final totalQuestions = questions.length;
    final controllerState = ref.watch(onboardingControllerProvider);
    final completionPct = controllerState.completionPercentage;

    return Scaffold(
      body: SafeArea(
        minimum: AppSpacing.horizontalScreen,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    locale.quizProgress(answeredCount, totalQuestions),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            FlatmatesStepProgress.segments(
              currentStep: completionPct.round(),
              totalSteps: 100,
            ),
            const SizedBox(height: AppSpacing.screen),
            Expanded(
              child: ListView(
                children: questions.map((q) {
                  final selected = _answers[q.key];
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppSpacing.lg + AppSpacing.sm,
                    ),
                    child: FlatmatesCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                q.emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  q.title(locale),
                                  style: theme.textTheme.titleLarge,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: q.options.map((opt) {
                              final isSelected = selected == opt.key;
                              return FlatmatesChip(
                                key: Key('quiz_${q.key}_${opt.key}'),
                                label: opt.label(locale),
                                variant: FlatmatesChipVariant.choice,
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    _answers[q.key] = opt.key;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FlatmatesButton(
              key: const Key('onboarding_quiz_next'),
              label: locale.onboardingNext,
              fullWidth: true,
              onPressed: answeredCount == totalQuestions
                  ? () => widget.onComplete(Map.from(_answers))
                  : null,
              icon: Icons.arrow_forward_rounded,
            ),
            const SizedBox(height: AppSpacing.screen),
          ],
        ),
      ),
    );
  }
}

class _QuizQuestion {
  const _QuizQuestion({
    required this.key,
    required this.emoji,
    required this.title,
    required this.options,
  });

  final String key;
  final String emoji;
  final String Function(AppLocalizations) title;
  final List<_QuizOption> options;
}

class _QuizOption {
  const _QuizOption({required this.key, required this.label});

  final String key;
  final String Function(AppLocalizations) label;
}
