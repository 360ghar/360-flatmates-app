import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Individual stat/action item in the property card grid.
class StatActionItem extends StatelessWidget {
  const StatActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final b = theme.brightness;
    // Disabled tiles use the brightness-aware muted token, never a light-only
    // colour at reduced opacity (it vanished on the dark card, #33).
    final color = enabled
        ? AppSemanticColors.clayFor(b)
        : AppSemanticColors.textTertiaryFor(b);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smBorder,
      child: ConstrainedBox(
        // 48 dp minimum target; grows with the text size.
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xs,
            horizontal: AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: enabled ? AppSemanticColors.textPrimaryFor(b) : color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row inside the stats dialog showing a single stat.
class StatDialogRow extends StatelessWidget {
  const StatDialogRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppSemanticColors.clayFor(theme.brightness),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
