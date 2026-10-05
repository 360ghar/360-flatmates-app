import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/components.dart';
import '../shared/presentation/paper/paper_scene.dart';

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

    // The neighbourhood scene marks the break between the two phases
    // (DESIGN.md rule 2). Inside the onboarding FlatmatesScreen.
    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PaperScene.hero(height: 200),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.lg,
                    AppSpacing.screen,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                          color: AppSemanticColors.textSecondaryFor(
                            theme.brightness,
                          ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
