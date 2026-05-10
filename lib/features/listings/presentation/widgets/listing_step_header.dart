import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/components.dart';
import 'listing_step_metadata.dart';

class ListingStepHeader extends StatelessWidget {
  const ListingStepHeader({
    required this.locale,
    required this.step,
    required this.totalSteps,
    required this.summary,
    super.key,
  });

  final AppLocalizations locale;
  final int step;
  final int totalSteps;
  final String? summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${locale.stepLabel} ${step + 1} ${locale.stepOfLabel} $totalSteps',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppSemanticColors.textSecondaryFor(theme.brightness),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FlatmatesStepProgress.segments(
            currentStep: step,
            totalSteps: totalSteps,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            listingStepTitle(locale, step),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            listingStepHelperText(locale, step),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppSemanticColors.textSecondaryFor(theme.brightness),
            ),
          ),
          if (summary != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              summary!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppSemanticColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
