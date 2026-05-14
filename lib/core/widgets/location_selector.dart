import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../theme/app_radius.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_spacing.dart';

class LocationSelector extends StatelessWidget {
  final String? displayText;
  final VoidCallback? onTap;

  const LocationSelector({super.key, this.displayText, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = AppLocalizations.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pillBorder,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppSemanticColors.darkSurface.withValues(alpha: 0.8)
              : AppSemanticColors.card.withValues(alpha: 0.9),
          borderRadius: AppRadius.pillBorder,
          border: Border.all(color: AppSemanticColors.line, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 18,
              color: AppSemanticColors.accent,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                displayText ?? locale.selectLocationLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: displayText != null
                      ? AppSemanticColors.textPrimaryFor(theme.brightness)
                      : AppSemanticColors.ink3,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppSemanticColors.ink3,
            ),
          ],
        ),
      ),
    );
  }
}
