import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_ui.dart';

class SwipeQuotaHeader extends StatelessWidget {
  const SwipeQuotaHeader({
    required this.swipesRemaining,
    required this.superLikesRemaining,
    super.key,
  });

  final int swipesRemaining;
  final int superLikesRemaining;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const FlatmatesLogo(compact: true),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                locale.swipeCounterLabel(swipesRemaining),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                locale.superLikeCapLabel(superLikesRemaining),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppSemanticColors.textTertiaryFor(theme.brightness),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
