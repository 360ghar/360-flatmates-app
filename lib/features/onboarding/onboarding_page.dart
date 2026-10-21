import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import 'onboarding_transition_page.dart';
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
        body: FlatmatesErrorState(
          message: message,
          onRetry: () => controller.submitNonNegotiables(state.nonNegotiables),
        ),
      );
    }

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
      OnboardingStep.transition => OnboardingTransitionPage(
        onContinue: () => unawaited(controller.continueFromTransition()),
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
            if (state.step != OnboardingStep.splash)
              _OnboardingProgressHeader(
                state: state,
                showWelcomeBack:
                    controller.resumedFromDraft &&
                    state.completionPercentage > 0 &&
                    state.step != OnboardingStep.modeSelection,
                onBack: controller.canGoBack
                    ? () => unawaited(controller.goBack())
                    : null,
              ),
            // Step content
            Expanded(child: stepWidget),
          ],
        ),
      ),
    );
  }
}

/// Maps an [OnboardingStep] to a human-readable label using the app's
/// localization strings. The transition step has no label of its own — the
/// phase label above it carries that meaning.
String _stepLabel(OnboardingStep step, AppLocalizations locale) {
  return switch (step) {
    OnboardingStep.splash => '',
    OnboardingStep.modeSelection => locale.onboardingStepMode,
    OnboardingStep.locationSelection => locale.onboardingStepLocation,
    OnboardingStep.basicInfo => locale.onboardingStepBasicInfo,
    OnboardingStep.profilePhoto => locale.onboardingStepPhoto,
    OnboardingStep.transition => '',
    OnboardingStep.lifestyleQuiz => locale.onboardingStepLifestyle,
    OnboardingStep.budgetTimeline => locale.onboardingStepBudget,
    OnboardingStep.preferences => locale.onboardingStepPreferences,
    OnboardingStep.nonNegotiables => locale.onboardingStepNonNegotiables,
  };
}

/// Progress for every step after the splash: Back (when there is an earlier
/// step), the phase and step, "Finish later", and one progress bar.
class _OnboardingProgressHeader extends StatelessWidget {
  const _OnboardingProgressHeader({
    required this.state,
    required this.showWelcomeBack,
    required this.onBack,
  });

  final OnboardingState state;
  final bool showWelcomeBack;

  /// Null on the first step: there is nothing to go back to.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final secondary = AppSemanticColors.textSecondaryFor(brightness);
    final stepLabel = _stepLabel(state.step, locale);
    final remaining = locale.onboardingStepsRemaining(state.remainingSteps);
    final percent = state.completionPercentage;

    // Chrome, like the tab strip: text scales, capped at 1.5x so the row
    // still fits a 320 dp phone.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.sm,
          AppSpacing.screen,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App-bar row: Back on the left, Finish later on the right.
            Row(
              children: [
                if (onBack != null)
                  FlatmatesChromeIconButton(
                    key: const Key('onboarding_back'),
                    onPressed: onBack,
                    icon: Icons.arrow_back_rounded,
                    tooltip: locale.backCta,
                  ),
                const Spacer(),
                // Setup is a soft gate: leaving is allowed. The shell banner
                // keeps reminding the user, and the router still gates Swipe,
                // Post and Chats until setup is finished.
                FlatmatesButton.tertiary(
                  key: const Key('onboarding_exit_cta'),
                  label: locale.onboardingFinishLaterCta,
                  onPressed: () => context.go('/discover'),
                ),
              ],
            ),
            Text(
              state.phase == OnboardingPhase.essentials
                  ? locale.onboardingPhaseOneTitle
                  : locale.onboardingPhaseTwoTitle,
              style: theme.textTheme.labelMedium,
            ),
            Text(
              stepLabel.isEmpty ? remaining : '$stepLabel · $remaining',
              style: theme.textTheme.bodySmall?.copyWith(color: secondary),
            ),
            if (showWelcomeBack)
              Text(
                locale.onboardingWelcomeBack,
                style: theme.textTheme.bodySmall?.copyWith(color: secondary),
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: percent / 100),
                    duration: AppMotion.durationOrZero(context, AppMotion.slow),
                    curve: AppMotion.paperOut,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: AppSpacing.xs,
                      borderRadius: AppRadius.pillBorder,
                      semanticsLabel: locale.onboardingProgressTitle,
                      backgroundColor: AppSemanticColors.disabledSurfaceFor(
                        brightness,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppSemanticColors.clayFor(brightness),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${percent.toInt()}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppSemanticColors.clayFor(brightness),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
