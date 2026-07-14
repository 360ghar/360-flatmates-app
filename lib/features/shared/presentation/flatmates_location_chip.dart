import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Shared location picker chrome used on Explore, Swipe, and Home.
///
/// Soft surface fill + location icon + truncated label + chevron.
/// Keeps Map and Swipe top bars in the same visual family.
class FlatmatesLocationChip extends StatefulWidget {
  const FlatmatesLocationChip({
    super.key,
    this.locationName,
    this.placeholder,
    this.onTap,
    this.dense = false,
  });

  final String? locationName;
  final String? placeholder;
  final VoidCallback? onTap;

  /// Compact padding for map overlays; default suits toolbar rows.
  final bool dense;

  @override
  State<FlatmatesLocationChip> createState() => _FlatmatesLocationChipState();
}

class _FlatmatesLocationChipState extends State<FlatmatesLocationChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final label = (widget.locationName?.trim().isNotEmpty ?? false)
        ? widget.locationName!.trim()
        : (widget.placeholder ?? '');
    final ink = AppSemanticColors.textPrimaryFor(brightness);
    final soft = AppSemanticColors.secondarySurfaceFor(brightness);
    final hPad = widget.dense ? AppSpacing.sm : AppSpacing.md;
    final vPad = widget.dense ? AppSpacing.xs + 2 : AppSpacing.sm;
    final iconSize = widget.dense ? 14.0 : 16.0;
    final labelSize = widget.dense
        ? AppTypography.microLabelSize
        : AppTypography.captionSmSize;
    final labelHeight = widget.dense
        ? AppTypography.microLabelHeight
        : AppTypography.captionSmHeight;

    final chip = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOutCubic,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: AppSemanticColors.hairlineFor(brightness)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_outlined, size: iconSize, color: ink),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: labelSize,
                height: labelHeight,
                color: ink,
              ),
            ),
          ),
          const SizedBox(width: 2),
          Icon(Icons.keyboard_arrow_down_rounded, size: iconSize, color: ink),
        ],
      ),
    );

    if (widget.onTap == null) return chip;

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: AppMotion.buttonPress,
          curve: AppMotion.easeOutCubic,
          child: chip,
        ),
      ),
    );
  }
}
