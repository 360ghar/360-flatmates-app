import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_radius.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_spacing.dart';

class LocationSelector extends StatelessWidget {
  final String? displayText;
  final VoidCallback? onTap;

  const LocationSelector({super.key, this.displayText, this.onTap});

  /// Label cap on a phone — the width the bar was designed around.
  static const double _phoneLabelCap = 160;

  /// Cap on the label's width at a [width]-wide viewport.
  ///
  /// A phone keeps the 160 dp the bar was designed around. From
  /// [AppBreakpoints.medium] up the cap follows the viewport instead of
  /// staying at 160: on the open Duo's 855 dp bar the selected locality was
  /// truncated at 160 dp with 700 dp of the bar sitting empty. It stops at
  /// half the reading column, so the label can never crowd the trailing
  /// chevron on a desktop-width viewport.
  ///
  /// A width-derived cap rather than a `Flexible`, deliberately: this row is
  /// laid out with [MainAxisSize.min], so the bar that holds it gives a
  /// non-flex child an unbounded width. A flex child here would trip
  /// `RenderFlex`'s "non-zero flex but incoming width constraints are
  /// unbounded" assertion in that bar. The cap is also what keeps the row
  /// inside its parent on a phone: the pill's chrome (icon, gaps, chevron and
  /// padding) is ~68 dp, so 160 + 68 still fits the 320 dp bar.
  static double labelCap(double width) =>
      (width * 0.5).clamp(_phoneLabelCap, AppBreakpoints.readingColumn / 2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = AppLocalizations.of(context);
    final cap = labelCap(MediaQuery.sizeOf(context).width);

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
          border: Border.all(
            color: AppSemanticColors.hairlineFor(theme.brightness),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 18,
              color: AppSemanticColors.accent,
            ),
            const SizedBox(width: AppSpacing.xs),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cap),
              child: Text(
                displayText ?? locale.selectLocationLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: displayText != null
                      ? AppSemanticColors.textPrimaryFor(theme.brightness)
                      : AppSemanticColors.textTertiaryFor(theme.brightness),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppSemanticColors.textTertiaryFor(theme.brightness),
            ),
          ],
        ),
      ),
    );
  }
}
