import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/l10n_bridge.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_dialog.dart';
import '../../../shared/presentation/flatmates_toast.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import '../../application/chat_actions_controller.dart';
import '../../domain/chat_report_reason.dart';

class ChatDialogs {
  static Future<void> showBlockDialog({
    required BuildContext context,
    required int peerId,
    required ChatActionsController controller,
  }) async {
    final locale = AppLocalizations.of(context);
    final confirmed = await FlatmatesDialog.confirm(
      context,
      title: locale.blockConfirmTitle,
      message: locale.blockConfirmMessage,
      cancelLabel: locale.cancelCta,
      confirmLabel: locale.blockCta,
      destructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await controller.blockUser(peerId);
      if (!context.mounted) return;
      FlatmatesToast.success(context, locale.userBlocked);
      if (context.mounted) {
        context.pop();
      }
    } on AppFailure catch (e) {
      if (context.mounted) {
        FlatmatesToast.error(
          context,
          e.userMessage(locale.toUserMessageL10n()),
        );
      }
    } catch (e) {
      debugPrint('ChatDialogs.showBlockDialog failed for peer $peerId: $e');
      if (context.mounted) {
        FlatmatesToast.error(context, locale.failedToBlockUser);
      }
    }
  }

  static Future<void> showReportDialog({
    required BuildContext context,
    required int peerId,
    required List<ChatReportReason> reasons,
    required ChatActionsController controller,
  }) async {
    final locale = AppLocalizations.of(context);
    String? selectedReason;
    final reasonLabels = reasons.map((r) => r.resolvedLabel(locale)).toList();

    final confirmed = await FlatmatesDialog.custom<String>(
      context,
      title: locale.reportTitle,
      body: (ctx, setDialogState) => RadioGroup<String>(
        groupValue: selectedReason,
        onChanged: (v) => setDialogState(() => selectedReason = v),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(reasons.length, (idx) {
            return ListTile(
              title: Text(reasonLabels[idx]),
              leading: Radio<String>(value: reasons[idx].value),
              onTap: () =>
                  setDialogState(() => selectedReason = reasons[idx].value),
              contentPadding: EdgeInsets.zero,
            );
          }),
        ),
      ),
      actions: (ctx, _, close) => [
        FlatmatesButton.tertiary(
          label: locale.cancelCta,
          onPressed: () => close(),
        ),
        FlatmatesButton(
          label: locale.reportCta,
          destructive: true,
          onPressed: selectedReason == null
              ? null
              : () => close(selectedReason),
        ),
      ],
    );
    if (confirmed == null || !context.mounted) return;

    try {
      await controller.reportUser(peerId, confirmed);
      if (!context.mounted) return;
      FlatmatesToast.success(context, locale.reportSubmitted);
    } on AppFailure catch (e) {
      if (context.mounted) {
        FlatmatesToast.error(
          context,
          e.userMessage(locale.toUserMessageL10n()),
        );
      }
    } catch (e) {
      debugPrint('ChatDialogs.showReportDialog failed for peer $peerId: $e');
      if (context.mounted) {
        FlatmatesToast.error(context, locale.failedToReportUser);
      }
    }
  }

  static Future<void> showUnmatchDialog({
    required BuildContext context,
    required int conversationId,
    required int peerId,
    required ChatActionsController controller,
  }) async {
    final locale = AppLocalizations.of(context);
    final confirmed = await FlatmatesDialog.confirm(
      context,
      title: locale.unmatchConfirmTitle,
      message: locale.unmatchConfirmMessage,
      cancelLabel: locale.cancelCta,
      confirmLabel: locale.unmatchCta,
      destructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await controller.unmatchConversation(conversationId, peerId);
      if (!context.mounted) return;
      FlatmatesToast.success(context, locale.userUnmatched);
      if (context.mounted) {
        context.pop();
      }
    } on AppFailure catch (e) {
      if (context.mounted) {
        FlatmatesToast.error(
          context,
          e.userMessage(locale.toUserMessageL10n()),
        );
      }
    } catch (e) {
      debugPrint(
        'ChatDialogs.showUnmatchDialog failed for conversation $conversationId: $e',
      );
      if (context.mounted) {
        FlatmatesToast.error(context, locale.failedToUnmatch);
      }
    }
  }
}
