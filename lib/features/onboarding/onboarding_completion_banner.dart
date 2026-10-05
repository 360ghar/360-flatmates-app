import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/components.dart';
import 'onboarding_controller.dart';

/// A persistent banner shown above the main app content when the user's
/// onboarding is incomplete. It communicates what's needed and provides a
/// one-tap shortcut back into the onboarding flow.
///
/// Shown inside [AppShell] on all accessible tabs (Discover, Map, Profile)
/// while the `app_onboarding` auth gate is active. Blocked tabs (Swipe, Post,
/// Chats) redirect to `/onboarding` via the router, so the banner is not
/// visible there.
class OnboardingCompletionBanner extends ConsumerWidget {
  const OnboardingCompletionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Watch the onboarding controller for the actual remaining step count.
    // If the draft hasn't hydrated yet, fall back to the total interactive
    // step count so the banner always shows a meaningful number.
    final onboardingState = ref.watch(onboardingControllerProvider);
    final remainingSteps = onboardingState.isHydrated
        ? onboardingState.remainingSteps
        : OnboardingState.totalInteractiveSteps;

    final brightness = theme.brightness;
    final clay = AppSemanticColors.clayFor(brightness);

    // A clay-soft strip in the page flow. The shell puts it under the status
    // bar inset and removes that inset from the page below.
    return Material(
      color: AppSemanticColors.coralSoftFor(brightness),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screen,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(Icons.rocket_launch_outlined, color: clay, size: 24),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      locale.onboardingActionBlockedTitle,
                      style: theme.textTheme.labelMedium,
                    ),
                    Text(
                      remainingSteps > 0
                          ? locale.onboardingStepsRemaining(remainingSteps)
                          : locale.onboardingActionBlockedMessage,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppSemanticColors.textSecondaryFor(brightness),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Flexible so a long label shrinks instead of overflowing.
              Flexible(
                child: FlatmatesButton(
                  key: const Key('onboarding_banner_cta'),
                  label: locale.onboardingActionBlockedCta,
                  onPressed: () => context.go('/onboarding'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
