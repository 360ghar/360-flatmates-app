import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';

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
        color: AppSemanticColors.pineSoftFor(Theme.of(context).brightness),
        borderRadius: AppRadius.smBorder,
        border: Border.all(
          color: AppSemanticColors.coralSoftFor(Theme.of(context).brightness),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppSemanticColors.clayFor(Theme.of(context).brightness),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppSemanticColors.textPrimaryFor(
                  Theme.of(context).brightness,
                ),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
