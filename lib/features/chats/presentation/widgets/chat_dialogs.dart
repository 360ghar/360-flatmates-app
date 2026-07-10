import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/l10n_bridge.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_bottom_sheet.dart';
import '../../../shared/presentation/flatmates_toast.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import '../../application/chat_actions_controller.dart';
import '../../domain/chat_report_reason.dart';

class ChatDialogs {
  /// Shows a block confirmation dialog.
  ///
  /// When [popOnSuccess] is true (default), the current route is popped after
  /// a successful block — intended for chat threads that should leave the
  /// conversation. Pass `false` for surfaces like the swipe deck that must
  /// stay on the same shell route.
  ///
  /// Returns `true` when the user was blocked successfully.
  static Future<bool> showBlockDialog({
    required BuildContext context,
    required int peerId,
    required ChatActionsController controller,
    bool popOnSuccess = true,
  }) async {
    final locale = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.blockConfirmTitle),
        content: Text(locale.blockConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(locale.cancelCta),
          ),
          FlatmatesButton(
            label: locale.blockCta,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return false;

    try {
      await controller.blockUser(peerId);
      if (!context.mounted) return false;
      FlatmatesToast.success(context, locale.userBlocked);
      if (popOnSuccess && context.mounted) {
        context.pop();
      }
      return true;
    } on AppFailure catch (e) {
      if (context.mounted) {
        FlatmatesToast.error(
          context,
          e.userMessage(locale.toUserMessageL10n()),
        );
      }
      return false;
    } catch (e) {
      debugPrint('ChatDialogs.showBlockDialog failed for peer $peerId: $e');
      if (context.mounted) {
        FlatmatesToast.error(context, locale.failedToBlockUser);
      }
      return false;
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

    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(locale.reportTitle),
          content: RadioGroup<String>(
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(locale.cancelCta),
            ),
            FlatmatesButton(
              label: locale.reportCta,
              onPressed: selectedReason != null
                  ? () => Navigator.pop(ctx, selectedReason)
                  : null,
            ),
          ],
        ),
      ),
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.unmatchConfirmTitle),
        content: Text(locale.unmatchConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(locale.cancelCta),
          ),
          FlatmatesButton(
            label: locale.unmatchCta,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await controller.unmatchConversation(conversationId, peerId);
      if (!context.mounted) return;
      context.pop();
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

  static void showChatMenu({
    required BuildContext context,
    required VoidCallback onBlock,
    required VoidCallback onReport,
    required VoidCallback onUnmatch,
  }) {
    final locale = AppLocalizations.of(context);
    FlatmatesBottomSheet.show(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(locale.reportCta),
              onTap: () {
                Navigator.pop(ctx);
                onReport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_off_outlined),
              title: Text(locale.unmatchCta),
              onTap: () {
                Navigator.pop(ctx);
                onUnmatch();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.block_outlined,
                color: AppSemanticColors.error,
              ),
              title: Text(
                locale.blockCta,
                style: const TextStyle(color: AppSemanticColors.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onBlock();
              },
            ),
          ],
        ),
      ),
    );
  }
}
