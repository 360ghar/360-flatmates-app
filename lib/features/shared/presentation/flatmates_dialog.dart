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
  /// Set [destructive] for irreversible actions (delete, block, sign out):
  /// the confirm button turns danger-red. A double tap closes the dialog
  /// once.
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
    final result = await custom<bool>(
      context,
      title: title,
      body: message == null
          ? null
          : (ctx, _) => Text(message, style: Theme.of(ctx).textTheme.bodyLarge),
      actions: (ctx, _, close) => [
        FlatmatesButton.tertiary(
          key: cancelKey,
          label: cancelLabel,
          onPressed: () => close(false),
        ),
        FlatmatesButton(
          key: confirmKey,
          label: confirmLabel,
          destructive: destructive,
          onPressed: () => close(true),
        ),
      ],
    );
    return result ?? false;
  }

  /// A paper dialog with stateful [body] and [actions]. Actions call
  /// `close(value)` to pop with a result; `close` ignores repeat calls, so a
  /// double tap can never pop the route underneath.
  static Future<T?> custom<T>(
    BuildContext context, {
    required String title,
    Widget Function(BuildContext ctx, StateSetter setState)? body,
    List<Widget> Function(
      BuildContext ctx,
      StateSetter setState,
      void Function([T? value]) close,
    )?
    actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        // Captured while the dialog builds: the route to pop, and the proof
        // that it is still the top route when a delayed action closes.
        final dialogRoute = ModalRoute.of(dialogContext);
        var closed = false;
        void close([T? value]) {
          if (closed) return;
          closed = true;
          // Back and barrier dismissal pop this route without calling close.
          // By the time a delayed action runs, the page underneath is current
          // and a second pop would close it, so only pop while the dialog's
          // own route is still the top one.
          if (!dialogContext.mounted) return;
          if (dialogRoute != null && !dialogRoute.isCurrent) return;
          Navigator.of(dialogContext).pop(value);
        }

        return StatefulBuilder(
          builder: (ctx, setState) {
            final text = Theme.of(ctx).textTheme;
            final actionWidgets = actions?.call(ctx, setState, close);
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(title, style: text.headlineSmall),
                      ),
                      if (body != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        body(ctx, setState),
                      ],
                      if (actionWidgets != null &&
                          actionWidgets.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: actionWidgets,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
