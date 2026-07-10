import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/l10n_bridge.dart';
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

    if (!state.isHydrated) {
      // Draft is still being read from SharedPreferences; render a placeholder
      // so we don't flash the default splash and then bounce the user into a
      // mid-flow step.
      return const FlatmatesScreen(body: FlatmatesSkeleton.form());
    }

    if (state.isComplete) {
      // The app router observes the local onboarding-complete override and
      // owns the transition into the authenticated shell.
      return const FlatmatesScreen(body: FlatmatesSkeleton.form());
    }

    if (state.isSubmitting) {
      return FlatmatesScreen(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.lg),
              Text(locale.onboardingSubmitting),
            ],
          ),
        ),
      );
    }

    if (state.hasError) {
      final message =
          state.failure?.userMessage(locale.toUserMessageL10n()) ??
          locale.onboardingSubmitError;
      return FlatmatesScreen(
        body: Center(
          child: Padding(
            padding: AppSpacing.horizontalScreen,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppSemanticColors.error,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.lg),
                FlatmatesButton(
                  key: const Key('onboarding_submit_retry'),
                  label: locale.commonRetry,
                  onPressed: () =>
                      controller.submitNonNegotiables(state.nonNegotiables),
                  fullWidth: true,
                ),
              ],
            ),
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
        onBack: () => unawaited(controller.goBack()),
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

    return PopScope(
      // Intercept system back so it steps backwards through the flow instead
      // of popping the whole onboarding route. When there is no earlier step
      // (mode selection) we allow the pop to fall through.
      canPop: !controller.canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(controller.goBack());
      },
      child: FlatmatesScreen(
        body: Column(
          children: [
            // Progress indicator
            if (state.step != OnboardingStep.splash)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  0,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          locale.onboardingProgressTitle,
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
                    const SizedBox(height: AppSpacing.sm),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: AppMotion.pageTransition,
                      curve: AppMotion.easeOutCubic,
                      builder: (context, animatedValue, child) {
                        return LinearProgressIndicator(
                          value: animatedValue,
                          backgroundColor: AppSemanticColors.disabledSurfaceFor(
                            theme.brightness,
                          ),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppSemanticColors.accent,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
