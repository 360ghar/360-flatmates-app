import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

enum PeerActionButtonColor { blue, green, pink, red }

/// Compact icon-over-label action button used in the peer profile action
/// strip (Message, Call, Schedule Visit, Report).
class PeerActionButton extends StatelessWidget {
  const PeerActionButton({
    required this.icon,
    required this.label,
    this.color = PeerActionButtonColor.pink,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final PeerActionButtonColor color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final enabled = onTap != null;
    final isDark = brightness == Brightness.dark;

    if (!enabled) {
      final disabledFg = AppSemanticColors.textTertiaryFor(brightness);
      return Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          decoration: const BoxDecoration(borderRadius: AppRadius.smBorder),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: disabledFg),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.microLabelSize,
                  fontWeight: FontWeight.w600,
                  color: disabledFg,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final bg = switch (color) {
      PeerActionButtonColor.blue =>
        isDark ? AppSemanticColors.blueSoftDark : AppSemanticColors.blueSoft,
      PeerActionButtonColor.green =>
        isDark ? AppSemanticColors.greenSoftDark : AppSemanticColors.greenSoft,
      PeerActionButtonColor.pink =>
        isDark ? AppSemanticColors.pinkSoftDark : AppSemanticColors.pinkSoft,
      PeerActionButtonColor.red =>
        isDark ? AppSemanticColors.errorSoftDark : AppSemanticColors.errorBg,
    };
    final fg = switch (color) {
      PeerActionButtonColor.blue => AppSemanticColors.blueInk,
      PeerActionButtonColor.green => AppSemanticColors.greenInk,
      PeerActionButtonColor.pink => AppSemanticColors.pinkInk,
      PeerActionButtonColor.red => AppSemanticColors.error,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smBorder,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.smBorder,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.microLabelSize,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
