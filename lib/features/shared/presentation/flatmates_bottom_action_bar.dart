import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'flatmates_ui.dart';

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

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppSemanticColors.frostBlur,
          sigmaY: AppSemanticColors.frostBlur,
        ),
        child: Container(
          padding: EdgeInsets.only(
            left: AppSpacing.screen,
            right: AppSpacing.screen,
            top: AppSpacing.md,
            bottom: bottomInset + AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppSemanticColors.frostOverlayDark
                : AppSemanticColors.frostOverlayLight,
            border: Border(
              top: BorderSide(
                color: AppSemanticColors.line.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
          ),
          child: _buildRow(isDark),
        ),
      ),
    );
  }

  Widget _buildRow(bool isDark) {
    if (tertiaryIcon != null) {
      return Row(
        children: [
          SizedBox(width: 52, height: 52, child: _tertiaryButtonView(isDark)),
          const SizedBox(width: AppSpacing.sm),
          if (secondaryLabel != null) ...[
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  key: secondaryButtonKey,
                  onPressed: secondaryOnPressed,
                  style: OutlinedButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.mdBorder,
                    ),
                    side: const BorderSide(color: AppSemanticColors.line),
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
              height: 52,
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
              height: 52,
              child: OutlinedButton(
                key: secondaryButtonKey,
                onPressed: secondaryOnPressed,
                style: OutlinedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.mdBorder,
                  ),
                  side: const BorderSide(color: AppSemanticColors.line),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: tertiaryButtonKey,
        onTap: tertiaryOnPressed,
        borderRadius: AppRadius.mdBorder,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdBorder,
            border: Border.all(
              color: tertiarySelected
                  ? AppSemanticColors.accent
                  : AppSemanticColors.line,
            ),
            color: tertiarySelected
                ? AppSemanticColors.accent.withValues(alpha: 0.1)
                : null,
          ),
          alignment: Alignment.center,
          child: Icon(
            tertiaryIcon,
            size: 22,
            color: tertiarySelected
                ? AppSemanticColors.accent
                : AppSemanticColors.textTertiaryFor(
                    isDark ? Brightness.dark : Brightness.light,
                  ),
          ),
        ),
      ),
    );
  }
}
