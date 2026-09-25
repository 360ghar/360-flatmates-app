import 'package:flutter/material.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'test_id.dart';

/// Standardized menu row for Profile and Settings screens: a bare clay icon
/// (danger when destructive), a label, an optional subtitle and a chevron.
class FlatmatesMenuItem extends StatefulWidget {
  const FlatmatesMenuItem({
    required this.label,
    required this.icon,
    super.key,
    this.subtitle,
    this.onTap,
    this.isDestructive = false,
    this.dense = false,
  });

  final String label;
  final IconData icon;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;

  /// Smaller padding and icon slot for compact lists (e.g. Me tab).
  final bool dense;

  static double _hPad(bool dense) => dense ? AppSpacing.base : AppSpacing.s20;
  static double _iconSlot(bool dense) => dense ? AppSpacing.xl : AppSpacing.s40;
  static const double _iconGap = AppSpacing.md;

  /// Distance from the row's leading edge to its label. Use it as the
  /// divider indent between rows so dividers line up with the text.
  static double labelInset({bool dense = false}) =>
      _hPad(dense) + _iconSlot(dense) + _iconGap;

  @override
  State<FlatmatesMenuItem> createState() => _FlatmatesMenuItemState();
}

class _FlatmatesMenuItemState extends State<FlatmatesMenuItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || AppMotion.reduceMotion(context)) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) =>
      withTestId(widget.key, _buildContent(context));

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final clay = AppSemanticColors.clayFor(brightness);
    final danger = AppSemanticColors.dangerFor(brightness);
    final dense = widget.dense;

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: AppRadius.mdBorder,
        splashColor: clay.withValues(alpha: 0.05),
        highlightColor: clay.withValues(alpha: 0.03),
        child: AnimatedScale(
          scale: _pressed ? AppMotion.pressScale : 1.0,
          duration: AppMotion.fast,
          curve: AppMotion.paperOut,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: FlatmatesMenuItem._hPad(dense),
              vertical: dense ? AppSpacing.md : AppSpacing.base,
            ),
            child: Row(
              children: [
                // Bare icon (no tinted tile), in a fixed-width slot so
                // labels align down the list.
                SizedBox(
                  width: FlatmatesMenuItem._iconSlot(dense),
                  child: Icon(
                    widget.icon,
                    size: dense ? 20 : 22,
                    color: widget.isDestructive ? danger : clay,
                  ),
                ),
                const SizedBox(width: FlatmatesMenuItem._iconGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: widget.isDestructive ? danger : null,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppSemanticColors.textSecondaryFor(
                              brightness,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppSemanticColors.textTertiaryFor(brightness),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
