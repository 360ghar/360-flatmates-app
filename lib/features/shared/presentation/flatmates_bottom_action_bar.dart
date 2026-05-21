import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'flatmates_ui.dart';

/// Sticky CTA bar with frosted-glass effect for details, listing steps, visits, etc.
///
/// Pins a primary action button to the bottom of the screen above safe area.
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
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Key? primaryButtonKey;

  /// Optional secondary (outline) button on the left.
  final String? secondaryLabel;
  final VoidCallback? secondaryOnPressed;
  final IconData? secondaryIcon;
  final Key? secondaryButtonKey;

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
          child: secondaryLabel != null
              ? Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          key: secondaryButtonKey,
                          onPressed: secondaryOnPressed,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.mdBorder,
                            ),
                            side: const BorderSide(
                              color: AppSemanticColors.line,
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
                )
              : FlatmatesButton(
                  key: primaryButtonKey,
                  label: label,
                  onPressed: onPressed,
                  icon: icon,
                ),
        ),
      ),
    );
  }
}
