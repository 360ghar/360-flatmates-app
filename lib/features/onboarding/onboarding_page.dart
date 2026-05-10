import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/components.dart';
import 'budget_timeline_page.dart';
import 'lifestyle_quiz_page.dart';
import 'location_selection_page.dart';
import 'mode_selection_page.dart';
import 'non_negotiables_page.dart';
import 'onboarding_controller.dart';
import 'onboarding_splash_pages.dart';
import 'preferences_page.dart';
import 'profile_photo_page.dart';
import 'basic_info_page.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (state.isComplete) {
      Future.microtask(() {
        if (context.mounted) context.go('/discover');
      });
      return const Scaffold(body: Center(child: FlatmatesSkeleton.card()));
    }

    if (state.isSubmitting) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(locale.onboardingSubmitting),
            ],
          ),
        ),
      );
    }

    if (state.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FlatmatesButton(
                label: locale.commonRetry,
                onPressed: () =>
                    controller.submitNonNegotiables(state.nonNegotiables),
                fullWidth: true,
              ),
            ],
          ),
        ),
      );
    }

    final progress = state.completionPercentage / 100;

    final stepWidget = switch (state.step) {
      OnboardingStep.splash => OnboardingSplashPages(
        onComplete: controller.completeSplash,
      ),
      OnboardingStep.modeSelection => ModeSelectionPage(
        onModeSelected: controller.setMode,
      ),
      OnboardingStep.locationSelection => LocationSelectionPage(
        onLocationSelected: controller.setLocation,
      ),
      OnboardingStep.basicInfo => BasicInfoPage(
        onNext: controller.setBasicInfo,
        initialCity: state.city,
        initialLocality: state.locality,
      ),
      OnboardingStep.profilePhoto => ProfilePhotoPage(
        onComplete: controller.setPhotoUrls,
      ),
      OnboardingStep.lifestyleQuiz => LifestyleQuizPage(
        onComplete: controller.setLifestyleAnswers,
      ),
      OnboardingStep.budgetTimeline => BudgetTimelinePage(
        onComplete: controller.setBudgetTimeline,
      ),
      OnboardingStep.preferences => PreferencesPage(
        onComplete: controller.setPreferences,
      ),
      OnboardingStep.nonNegotiables => NonNegotiablesPage(
        onComplete: controller.submitNonNegotiables,
      ),
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            if (state.step != OnboardingStep.splash)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Profile Setup',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${state.completionPercentage.toInt()}%',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppSemanticColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppSemanticColors.disabledSurfaceFor(
                        theme.brightness,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppSemanticColors.accent,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            // Step content
            Expanded(child: stepWidget),
          ],
        ),
      ),
    );
  }
}
