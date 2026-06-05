import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flatmates_app/core/theme/app_spacing.dart';

/// Availability tile for the 2-column grid on the flat details page.
class AvailabilityTile extends StatelessWidget {
  const AvailabilityTile({required this.label, required this.value, super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: AppSpacing.edgeMd,
      decoration: BoxDecoration(
        color: AppSemanticColors.secondarySurfaceFor(theme.brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppSemanticColors.line.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppSemanticColors.textSecondaryFor(theme.brightness),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Label-value row for the cost breakdown card.
class CostRow extends StatelessWidget {
  const CostRow({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppSemanticColors.textSecondaryFor(theme.brightness),
            ),
          ),
        ),
        Flexible(child: child),
      ],
    );
  }
}
