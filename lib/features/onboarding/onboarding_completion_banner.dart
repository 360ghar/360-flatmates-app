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
    final isDark = theme.brightness == Brightness.dark;

    // Watch the onboarding controller for the actual remaining step count.
    // If the draft hasn't hydrated yet, fall back to the total interactive
    // step count so the banner always shows a meaningful number.
    final onboardingState = ref.watch(onboardingControllerProvider);
    final remainingSteps = onboardingState.isHydrated
        ? onboardingState.remainingSteps
        : OnboardingState.totalInteractiveSteps;

    return Material(
      color: isDark
          ? AppSemanticColors.darkSurface
          : AppSemanticColors.accent.withAlpha(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppSemanticColors.accent.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppSemanticColors.accent.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rocket_launch_outlined,
                color: AppSemanticColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    locale.onboardingActionBlockedTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    remainingSteps > 0
                        ? locale.onboardingStepsRemaining(remainingSteps)
                        : locale.onboardingActionBlockedMessage,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            FlatmatesButton(
              key: const Key('onboarding_banner_cta'),
              label: locale.onboardingActionBlockedCta,
              onPressed: () => context.go('/onboarding'),
              icon: Icons.arrow_forward_rounded,
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
}
