import 'package:flutter/material.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_semantic_colors.dart';

/// Standardized menu row for Profile and Settings screens.
/// Matches screenshot #15 / #19 menu item pattern.
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

  /// Smaller padding and icon well for compact lists (e.g. Me tab).
  final bool dense;

  @override
  State<FlatmatesMenuItem> createState() => _FlatmatesMenuItemState();
}

class _FlatmatesMenuItemState extends State<FlatmatesMenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _menuIconPalette(widget.icon, widget.isDestructive, theme);
    final textColor = widget.isDestructive ? AppSemanticColors.error : null;
    final dense = widget.dense;
    final hPad = dense ? 16.0 : 20.0;
    final vPad = dense ? 10.0 : 14.0;
    final iconWell = dense ? 32.0 : 40.0;
    final iconSize = dense ? 18.0 : 20.0;
    final iconGap = dense ? 12.0 : 14.0;

    return Listener(
      onPointerDown: widget.onTap != null
          ? (_) => setState(() => _pressed = true)
          : null,
      onPointerUp: widget.onTap != null
          ? (_) => setState(() => _pressed = false)
          : null,
      onPointerCancel: widget.onTap != null
          ? (_) => setState(() => _pressed = false)
          : null,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppSemanticColors.accent.withValues(alpha: 0.05),
        highlightColor: AppSemanticColors.accent.withValues(alpha: 0.03),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: AppMotion.buttonPress,
          curve: AppMotion.easeOutCubic,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            child: Row(
              children: [
                AnimatedOpacity(
                  opacity: _pressed ? 0.8 : 1.0,
                  duration: AppMotion.fast,
                  // Bare icon (no tinted tile), kept in a fixed-width slot so
                  // labels align down the list.
                  child: SizedBox(
                    width: iconWell,
                    height: iconWell,
                    child: Icon(
                      widget.icon,
                      size: iconSize,
                      color: palette.foreground,
                    ),
                  ),
                ),
                SizedBox(width: iconGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppSemanticColors.textTertiaryFor(theme.brightness),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

_MenuIconPalette _menuIconPalette(
  IconData icon,
  bool isDestructive,
  ThemeData theme,
) {
  final isDark = theme.brightness == Brightness.dark;
  if (isDestructive) {
    return _MenuIconPalette(
      background: isDark
          ? AppSemanticColors.errorSoftDark
          : AppSemanticColors.errorSoft,
      foreground: AppSemanticColors.error,
    );
  }

  Color soft;
  Color darkSoft;
  Color mid;
  if (icon == Icons.calendar_month_outlined ||
      icon == Icons.calendar_month ||
      icon == Icons.event_available_outlined) {
    soft = AppSemanticColors.tealSoft;
    darkSoft = AppSemanticColors.tealSoftDark;
    mid = AppSemanticColors.tealMid;
  } else if (icon == Icons.favorite_border ||
      icon == Icons.favorite_rounded ||
      icon == Icons.favorite_outline) {
    soft = AppSemanticColors.pinkSoft;
    darkSoft = AppSemanticColors.pinkSoftDark;
    mid = AppSemanticColors.pinkMid;
  } else if (icon == Icons.chat_bubble_outline ||
      icon == Icons.chat_bubble_rounded ||
      icon == Icons.message_outlined) {
    soft = AppSemanticColors.blueSoft;
    darkSoft = AppSemanticColors.blueSoftDark;
    mid = AppSemanticColors.blueMid;
  } else if (icon == Icons.description_outlined ||
      icon == Icons.article_outlined ||
      icon == Icons.assignment_outlined) {
    soft = AppSemanticColors.yellowSoft;
    darkSoft = AppSemanticColors.yellowSoftDark;
    mid = AppSemanticColors.yellowMid;
  } else if (icon == Icons.payment_outlined ||
      icon == Icons.account_balance_wallet_outlined ||
      icon == Icons.wallet_outlined) {
    soft = AppSemanticColors.greenSoft;
    darkSoft = AppSemanticColors.greenSoftDark;
    mid = AppSemanticColors.greenMid;
  } else if (icon == Icons.settings_outlined ||
      icon == Icons.tune ||
      icon == Icons.tune_rounded ||
      icon == Icons.lock_outline ||
      icon == Icons.privacy_tip_outlined) {
    soft = AppSemanticColors.purpleSoft;
    darkSoft = AppSemanticColors.purpleSoftDark;
    mid = AppSemanticColors.purpleMid;
  } else if (icon == Icons.help_outline ||
      icon == Icons.support_agent_outlined ||
      icon == Icons.headset_mic_outlined) {
    soft = AppSemanticColors.orangeSoft;
    darkSoft = AppSemanticColors.orangeSoftDark;
    mid = AppSemanticColors.orangeMid;
  } else {
    soft = AppSemanticColors.coralSoft;
    darkSoft = AppSemanticColors.coralSoftDark;
    mid = AppSemanticColors.accent;
  }

  return _MenuIconPalette(
    background: isDark ? darkSoft : soft,
    foreground: mid,
  );
}

class _MenuIconPalette {
  const _MenuIconPalette({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
