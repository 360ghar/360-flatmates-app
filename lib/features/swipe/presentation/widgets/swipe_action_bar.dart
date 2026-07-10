import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// Tappable Skip / Undo / Like controls so the deck is fully operable without
/// swipe gestures (accessibility requirement). Buttons are disabled while a
/// swipe animation is in flight to avoid double-fires.
class SwipeActionBar extends StatelessWidget {
  const SwipeActionBar({
    required this.onSkip,
    required this.onLike,
    required this.onUndo,
    required this.canUndo,
    required this.enabled,
    super.key,
  });

  /// Called when the user taps the skip (pass) button.
  final VoidCallback onSkip;

  /// Called when the user taps the like button.
  final VoidCallback onLike;

  /// Called when the user taps the undo button.
  final VoidCallback onUndo;

  /// Whether an undo is currently available.
  final bool canUndo;

  /// Whether the action buttons accept input (false while animating).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    // No horizontal padding: bar is hosted inside the profile card scroll
    // (card chrome already insets from the screen edge).
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SwipeActionButton(
          key: const Key('swipe_action_skip'),
          icon: Icons.close_rounded,
          color: AppSemanticColors.compatLow,
          tooltip: locale.swipeSkipAction,
          semanticLabel: locale.swipeSkipAction,
          size: 60,
          onPressed: enabled ? onSkip : null,
        ),
        const SizedBox(width: AppSpacing.xl),
        _SwipeActionButton(
          key: const Key('swipe_action_undo'),
          icon: Icons.undo_rounded,
          color: AppSemanticColors.warning,
          tooltip: locale.swipeUndoAction,
          semanticLabel: locale.swipeUndoAction,
          size: 48,
          onPressed: (enabled && canUndo) ? onUndo : null,
        ),
        const SizedBox(width: AppSpacing.xl),
        _SwipeActionButton(
          key: const Key('swipe_action_like'),
          icon: Icons.favorite_rounded,
          color: AppSemanticColors.success,
          tooltip: locale.swipeLikeAction,
          semanticLabel: locale.swipeLikeAction,
          size: 60,
          onPressed: enabled ? onLike : null,
        ),
      ],
    );
  }
}

class _SwipeActionButton extends StatefulWidget {
  const _SwipeActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.semanticLabel,
    required this.size,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final String semanticLabel;
  final double size;
  final VoidCallback? onPressed;

  @override
  State<_SwipeActionButton> createState() => _SwipeActionButtonState();
}

class _SwipeActionButtonState extends State<_SwipeActionButton> {
  double _scale = 1.0;

  void _setScale(double value) {
    if (widget.onPressed == null) return;
    setState(() => _scale = value);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final theme = Theme.of(context);
    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        enabled: !disabled,
        label: widget.semanticLabel,
        child: Listener(
          onPointerDown: (_) => _setScale(0.97),
          onPointerUp: (_) => _setScale(1.0),
          onPointerCancel: (_) => _setScale(1.0),
          child: GestureDetector(
            onTap: widget.onPressed,
            child: AnimatedScale(
              scale: _scale,
              duration: AppMotion.buttonPress,
              curve: AppMotion.easeOutCubic,
              child: Opacity(
                opacity: disabled ? 0.4 : 1.0,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: widget.size * 0.42,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
