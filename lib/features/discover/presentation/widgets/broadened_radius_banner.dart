import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Compact info banner shown when the discover feed broadened its radius
/// beyond the user's selected area because the user's radius returned zero
/// listings.
class BroadenedRadiusBanner extends StatelessWidget {
  const BroadenedRadiusBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppSemanticColors.infoBg,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppSemanticColors.primaryDisabled),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppSemanticColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppSemanticColors.ink,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
