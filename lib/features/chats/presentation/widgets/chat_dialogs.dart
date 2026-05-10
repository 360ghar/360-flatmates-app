import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/l10n_bridge.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_bottom_sheet.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import '../../chats_repository.dart';
import '../../domain/chat_report_reason.dart';

class ChatDialogs {
  static Future<void> showBlockDialog({
    required BuildContext context,
    required int peerId,
    required ChatsRepository repository,
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
    if (confirmed != true || !context.mounted) return;

    try {
      await repository.blockUser(peerId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.userBlocked)));
      if (context.mounted) {
        context.pop();
      }
    } on AppFailure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.userMessage(locale.toUserMessageL10n()))),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(locale.failedToBlockUser)));
      }
    }
  }

  static Future<void> showReportDialog({
    required BuildContext context,
    required int peerId,
    required List<ChatReportReason> reasons,
    required ChatsRepository repository,
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
      await repository.reportUser(peerId, confirmed);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.reportSubmitted)));
    } on AppFailure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.userMessage(locale.toUserMessageL10n()))),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(locale.failedToReportUser)));
      }
    }
  }

  static Future<void> showUnmatchDialog({
    required BuildContext context,
    required int conversationId,
    required int peerId,
    required ChatsRepository repository,
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
      await repository.unmatchConversation(conversationId, peerId);
      if (!context.mounted) return;
      context.pop();
    } on AppFailure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.userMessage(locale.toUserMessageL10n()))),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(locale.failedToUnmatch)));
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
              leading: Icon(
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
