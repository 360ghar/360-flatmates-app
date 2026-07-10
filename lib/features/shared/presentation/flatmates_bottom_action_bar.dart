import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'flatmates_ui.dart';

/// Sticky bottom CTA bar — flat canvas + top hairline (Airbnb reservation language).
class FlatmatesBottomActionBar extends StatelessWidget {
  const FlatmatesBottomActionBar({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.primaryButtonKey,
    this.secondaryLabel,
    this.secondaryOnPressed,
    this.secondaryIcon,
    this.secondaryButtonKey,
    this.tertiaryIcon,
    this.tertiaryOnPressed,
    this.tertiaryButtonKey,
    this.tertiaryLabel,
    this.tertiarySelected = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Key? primaryButtonKey;

  final String? secondaryLabel;
  final VoidCallback? secondaryOnPressed;
  final IconData? secondaryIcon;
  final Key? secondaryButtonKey;

  final IconData? tertiaryIcon;
  final VoidCallback? tertiaryOnPressed;
  final Key? tertiaryButtonKey;
  final String? tertiaryLabel;
  final bool tertiarySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final surface = isDark
        ? AppSemanticColors.darkSurface
        : AppSemanticColors.canvas;
    final hairline = AppSemanticColors.hairlineFor(theme.brightness);

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.screen,
        right: AppSpacing.screen,
        top: AppSpacing.md,
        bottom: bottomInset + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: hairline)),
      ),
      child: _buildRow(isDark),
    );
  }

  Widget _buildRow(bool isDark) {
    if (tertiaryIcon != null) {
      return Row(
        children: [
          SizedBox(width: 48, height: 48, child: _tertiaryButtonView(isDark)),
          const SizedBox(width: AppSpacing.sm),
          if (secondaryLabel != null) ...[
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  key: secondaryButtonKey,
                  onPressed: secondaryOnPressed,
                  style: OutlinedButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.smBorder,
                    ),
                    side: BorderSide(
                      color: isDark
                          ? AppSemanticColors.darkHairline
                          : AppSemanticColors.ink,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (secondaryIcon != null) ...[
                        Icon(secondaryIcon, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Flexible(
                        child: Text(
                          secondaryLabel!,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: SizedBox(
              height: 48,
              child: FlatmatesButton(
                key: primaryButtonKey,
                label: label,
                onPressed: onPressed,
                icon: icon,
              ),
            ),
          ),
        ],
      );
    }

    if (secondaryLabel != null) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                key: secondaryButtonKey,
                onPressed: secondaryOnPressed,
                style: OutlinedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.smBorder,
                  ),
                  side: BorderSide(
                    color: isDark
                        ? AppSemanticColors.darkHairline
                        : AppSemanticColors.ink,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (secondaryIcon != null) ...[
                      Icon(secondaryIcon, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Flexible(
                      child: Text(
                        secondaryLabel!,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: FlatmatesButton(
              key: primaryButtonKey,
              label: label,
              onPressed: onPressed,
              icon: icon,
            ),
          ),
        ],
      );
    }

    return FlatmatesButton(
      key: primaryButtonKey,
      label: label,
      onPressed: onPressed,
      icon: icon,
    );
  }

  Widget _tertiaryButtonView(bool isDark) {
    final selected = tertiarySelected;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: tertiaryButtonKey,
        onTap: tertiaryOnPressed,
        borderRadius: AppRadius.smBorder,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.smBorder,
            border: Border.all(
              color: selected
                  ? AppSemanticColors.primary
                  : (isDark
                        ? AppSemanticColors.darkHairline
                        : AppSemanticColors.hairline),
            ),
            color: selected
                ? AppSemanticColors.primary.withValues(alpha: 0.08)
                : null,
          ),
          alignment: Alignment.center,
          child: Icon(
            tertiaryIcon,
            size: 22,
            color: selected
                ? AppSemanticColors.primary
                : AppSemanticColors.textTertiaryFor(
                    isDark ? Brightness.dark : Brightness.light,
                  ),
          ),
        ),
      ),
    );
  }
}
