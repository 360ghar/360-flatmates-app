import 'package:flutter/material.dart';

import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'paper/paper_edge_border.dart';
import 'paper/paper_surface.dart';

/// Toasts as paper strips: layer three, scalloped left edge, e3 shadow
/// (DESIGN.md §8). The icon carries the status colour; text stays ink.
///
/// Usage:
/// ```dart
/// FlatmatesToast.success(context, 'Profile updated');
/// FlatmatesToast.error(context, 'Something went wrong');
/// FlatmatesToast.info(context, 'Check your network');
/// ```
abstract final class FlatmatesToast {
  static void success(BuildContext context, String message) {
    _show(context, message: message, type: _ToastType.success);
  }

  static void error(BuildContext context, String message) {
    _show(context, message: message, type: _ToastType.error);
  }

  static void info(BuildContext context, String message) {
    _show(context, message: message, type: _ToastType.info);
  }

  static void _show(
    BuildContext context, {
    required String message,
    required _ToastType type,
  }) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: type._duration,
        content: Semantics(
          liveRegion: true,
          child: PaperSurface(
            layer: PaperLayer.three,
            elevation: PaperElevation.e3,
            edge: PaperEdge.scallop,
            edgeSide: PaperEdgeSide.left,
            edgeDepth: 6,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.base,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(type._icon, size: 22, color: type._iconColor(brightness)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppSemanticColors.textPrimaryFor(brightness),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ToastType { success, error, info }

extension on _ToastType {
  Duration get _duration => switch (this) {
    _ToastType.error => const Duration(seconds: 4),
    _ToastType.success => const Duration(seconds: 2),
    _ToastType.info => const Duration(seconds: 3),
  };

  IconData get _icon => switch (this) {
    _ToastType.success => Icons.check_circle_rounded,
    _ToastType.error => Icons.error_rounded,
    _ToastType.info => Icons.info_rounded,
  };

  Color _iconColor(Brightness b) => switch (this) {
    _ToastType.success => AppSemanticColors.pineFor(b),
    _ToastType.error => AppSemanticColors.dangerFor(b),
    _ToastType.info => AppSemanticColors.clayFor(b),
  };
}
