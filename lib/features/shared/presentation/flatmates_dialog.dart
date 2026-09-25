import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import 'flatmates_button.dart';
import 'paper/paper_surface.dart';

/// Shared dialogs on the paper treatment (layer three, e3).
abstract final class FlatmatesDialog {
  /// Asks the user to confirm an action. Resolves to true only when the
  /// user taps [confirmLabel]; dismissing or cancelling resolves to false.
  ///
  /// Set [destructive] for irreversible actions (delete, sign out, cancel a
  /// visit): the confirm button turns danger-red.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    required String cancelLabel,
    String? message,
    bool destructive = false,
    Key? confirmKey,
    Key? cancelKey,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final text = Theme.of(dialogContext).textTheme;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(AppSpacing.lg),
          child: PaperSurface(
            layer: PaperLayer.three,
            elevation: PaperElevation.e3,
            borderRadius: AppRadius.lgBorder,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.base,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: text.headlineSmall),
                ),
                if (message != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(message, style: text.bodyLarge),
                ],
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FlatmatesButton.tertiary(
                      key: cancelKey,
                      label: cancelLabel,
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                    ),
                    FlatmatesButton(
                      key: confirmKey,
                      label: confirmLabel,
                      destructive: destructive,
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }
}
