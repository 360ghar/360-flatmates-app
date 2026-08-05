import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/components.dart';

/// Screen shown between onboarding phase 1 (essentials) and phase 2
/// (lifestyle & preferences). Purely informational: the user taps continue
/// to start the second half of setup.
class OnboardingTransitionPage extends ConsumerWidget {
  const OnboardingTransitionPage({required this.onContinue, super.key});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return FlatmatesScreen(
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.horizontalScreen,
          child: FlatmatesCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 48,
                  color: AppSemanticColors.accent,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  locale.onboardingTransitionTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  locale.onboardingTransitionBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FlatmatesButton(
                  key: const Key('onboarding_transition_next'),
                  label: locale.onboardingTransitionCta,
                  fullWidth: true,
                  onPressed: onContinue,
                  icon: Icons.arrow_forward_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
