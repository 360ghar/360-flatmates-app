import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/compatibility/compatibility_engine.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_bottom_sheet.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import '../../chats_repository.dart';
import '../../domain/chat_report_reason.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({
    required this.conversationId,
    required this.conversation,
    required this.reportReasons,
    required this.onBlock,
    required this.onReport,
    required this.onUnmatch,
    required this.onCall,
    required this.onScheduleVisit,
    super.key,
  });

  final int conversationId;
  final ConversationSummaryModel? conversation;
  final List<ChatReportReason> reportReasons;
  final VoidCallback onBlock;
  final VoidCallback onReport;
  final VoidCallback onUnmatch;
  final VoidCallback onCall;
  final VoidCallback onScheduleVisit;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  double? _computeCompatibilityScore() {
    final peer = conversation?.peer;
    if (peer == null) return null;
    return peer.matchPercentage;
  }

  void _showChatMenu(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final score = _computeCompatibilityScore();

    return AppBar(
      titleSpacing: 0,
      leadingWidth: 40,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 22),
        onPressed: () => context.pop(),
        tooltip: 'Back',
      ),
      title: Row(
        children: [
          FlatmatesAvatar(
            name: conversation?.peer.fullName,
            imageUrl: conversation?.peer.profileImageUrl,
            size: 40,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        conversation?.peer.fullName ?? locale.chatsTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: AppTypography.h3Weight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    if (score != null)
                      Container(
                        width: AppSpacing.sm,
                        height: AppSpacing.sm,
                        decoration: BoxDecoration(
                          color: compatibilityScoreColor(score),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (conversation?.peer.mode != null) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppSemanticColors.accent.withValues(alpha: 0.4),
                      ),
                      borderRadius: AppRadius.smBorder,
                    ),
                    child: Text(
                      localizedFlatmatesModeLabel(
                        locale,
                        conversation?.peer.mode ?? '',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: AppTypography.captionSize,
                        fontWeight: AppTypography.labelMediumWeight,
                        color: AppSemanticColors.accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          key: const Key('chat_call_button'),
          onPressed: onCall,
          icon: Icon(
            Icons.call_outlined,
            color: AppSemanticColors.textSecondaryFor(theme.brightness),
            size: 20,
          ),
          tooltip: 'Call',
        ),
        if (conversation?.contextProperty != null)
          IconButton(
            key: const Key('chat_schedule_visit_button'),
            onPressed: onScheduleVisit,
            icon: Icon(
              Icons.event_available_outlined,
              color: AppSemanticColors.textSecondaryFor(theme.brightness),
              size: 20,
            ),
            tooltip: 'Schedule visit',
          ),
        IconButton(
          key: const Key('chat_more_button'),
          onPressed: () => _showChatMenu(context),
          icon: Icon(
            Icons.more_vert_rounded,
            color: AppSemanticColors.textSecondaryFor(theme.brightness),
            size: 20,
          ),
          tooltip: 'More options',
        ),
      ],
    );
  }
}
