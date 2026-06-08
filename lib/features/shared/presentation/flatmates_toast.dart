import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';

/// Consistent toast/snackbar utility with visual differentiation for
/// success, error, and info messages.
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

  static void _show(BuildContext context, {
    required String message,
    required _ToastType type,
  }) {
    final brightness = Theme.of(context).brightness;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(type._icon(brightness), size: 20, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        duration: type._duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: type._backgroundColor(brightness),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  IconData _icon(Brightness brightness) => switch (this) {
    _ToastType.success => Icons.check_circle_outline,
    _ToastType.error => Icons.error_outline,
    _ToastType.info => Icons.info_outline,
  };

  Color _backgroundColor(Brightness brightness) => switch (this) {
    _ToastType.success => AppSemanticColors.success,
    _ToastType.error => AppSemanticColors.error,
    _ToastType.info => AppSemanticColors.ink,
  };
}
