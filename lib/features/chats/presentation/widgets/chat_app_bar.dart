import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_bottom_sheet.dart';
import '../../../shared/presentation/flatmates_chrome_icon_button.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import '../../chats_repository.dart';
import '../../domain/chat_report_reason.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({
    required this.conversationId,
    required this.conversation,
    required this.avatarLink,
    required this.reportReasons,
    required this.onBlock,
    required this.onReport,
    required this.onUnmatch,
    required this.onCall,
    required this.onScheduleVisit,
    this.onPeerTap,
    super.key,
  });

  final int conversationId;
  final ConversationSummaryModel? conversation;

  /// Shared with the floating mode tooltip so its tail points at this avatar.
  final LayerLink avatarLink;
  final List<ChatReportReason> reportReasons;
  final VoidCallback onBlock;
  final VoidCallback onReport;
  final VoidCallback onUnmatch;
  final VoidCallback onCall;
  final VoidCallback onScheduleVisit;
  final VoidCallback? onPeerTap;

  static const double toolbarHeight = 64;

  @override
  Size get preferredSize => const Size.fromHeight(toolbarHeight);

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
    final brightness = theme.brightness;
    final score = _computeCompatibilityScore();
    final hairline = AppSemanticColors.hairlineFor(brightness);

    return AppBar(
      toolbarHeight: toolbarHeight,
      titleSpacing: 0,
      leadingWidth: 56,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: FlatmatesChromeIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => context.pop(),
          tooltip: locale.backCta,
        ),
      ),
      title: GestureDetector(
        key: const Key('chat_peer_header'),
        behavior: HitTestBehavior.opaque,
        onTap: onPeerTap,
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CompositedTransformTarget(
                  link: avatarLink,
                  child: FlatmatesAvatar(
                    name: conversation?.peer.fullName,
                    imageUrl: conversation?.peer.profileImageUrl,
                    size: 36,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppSemanticColors.scaffoldFor(brightness),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          conversation?.peer.fullName ?? locale.chatsTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: AppTypography.titleMdSize,
                            fontWeight: AppTypography.titleMdWeight,
                            height: AppTypography.titleMdHeight,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        FlatmatesChromeIconButton(
          key: const Key('chat_call_button'),
          onPressed: onCall,
          icon: Icons.call_outlined,
          tooltip: locale.callCta,
        ),
        if (conversation?.contextProperty != null)
          FlatmatesChromeIconButton(
            key: const Key('chat_schedule_visit_button'),
            onPressed: onScheduleVisit,
            icon: Icons.event_available_outlined,
            tooltip: locale.scheduleVisitCta,
          ),
        FlatmatesChromeIconButton(
          key: const Key('chat_more_button'),
          onPressed: () => _showChatMenu(context),
          icon: Icons.more_vert_rounded,
          tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
      shape: Border(bottom: BorderSide(color: hairline)),
    );
  }
}
