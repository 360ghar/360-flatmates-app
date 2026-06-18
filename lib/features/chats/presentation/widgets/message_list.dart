import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_empty_state.dart';
import '../../../shared/presentation/flatmates_error_state.dart';
import '../../../shared/presentation/flatmates_skeleton.dart';
import '../../application/messages_controller.dart';
import '../../chats_repository.dart';
import '../../../visits/visits_repository.dart';
import 'chat_message_bubble.dart';

class MessageList extends StatefulWidget {
  const MessageList({
    required this.messagesState,
    required this.currentUserId,
    required this.conversation,
    required this.visitsAsync,
    required this.onConfirmVisit,
    required this.onRescheduleVisit,
    super.key,
  });

  final MessagesState messagesState;
  final int currentUserId;
  final ConversationSummaryModel? conversation;
  final AsyncValue<List<VisitItem>> visitsAsync;
  final ValueChanged<VisitItem> onConfirmVisit;
  final ValueChanged<VisitItem> onRescheduleVisit;

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Keyboard open/close changes the viewport; keep the latest message in
    // view so the composer never hides the message the user just sent.
    _scrollToBottom(animated: true);
  }

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final count = widget.messagesState.displayMessages.length;
    // Detect a conversation switch: even if the message count is unchanged,
    // a different thread must be re-pinned to the bottom so the user lands on
    // the newest message instead of inheriting the previous thread's offset.
    final conversationChanged =
        widget.conversation?.id != oldWidget.conversation?.id;
    if (conversationChanged) {
      _lastMessageCount = count;
      _scrollToBottom(animated: false);
    } else if (count != _lastMessageCount) {
      // A message arrived (live, optimistic, or refetch) or the thread loaded:
      // pin the view to the newest message at the bottom.
      _scrollToBottom(animated: _lastMessageCount > 0);
      _lastMessageCount = count;
    }
  }

  void _scrollToBottom({required bool animated}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  bool _isMessageFromToday(DateTime createdAt) {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final messagesState = widget.messagesState;
    final currentUserId = widget.currentUserId;
    final conversation = widget.conversation;
    final visitsAsync = widget.visitsAsync;

    if (messagesState.isLoading && messagesState.displayMessages.isEmpty) {
      return const FlatmatesSkeleton.chatMessages();
    }
    if (messagesState.hasError && messagesState.displayMessages.isEmpty) {
      return FlatmatesErrorState(message: locale.couldNotLoadMessages);
    }

    final items = messagesState.displayMessages;
    if (items.isEmpty) {
      return FlatmatesEmptyState(
        title: locale.startAConversation,
        subtitle: locale.sayHelloOrIcebreaker,
        icon: Icons.chat_bubble_outline_rounded,
      );
    }

    // First non-empty render (e.g. thread opened with messages already in
    // state): jump to the bottom without animation.
    if (_lastMessageCount == 0) {
      _scrollToBottom(animated: false);
      _lastMessageCount = items.length;
    }

    final todayDividerIndex = items.indexWhere(
      (m) => _isMessageFromToday(m.createdAt),
    );
    final showTodayDivider = todayDividerIndex >= 0;
    final visitsById = {
      for (final visit in visitsAsync.valueOrNull ?? const <VisitItem>[])
        visit.id: visit,
    };

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      itemCount: items.length + (showTodayDivider ? 1 : 0),
      itemBuilder: (context, index) {
        if (showTodayDivider && index == todayDividerIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: AppSemanticColors.line.withValues(alpha: 0.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    locale.todayLabel,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: AppSemanticColors.line.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        }

        final itemIndex = showTodayDivider
            ? (index < todayDividerIndex ? index : index - 1)
            : index;
        final item = items[itemIndex];
        final isMine = item.senderId == currentUserId;
        final visit = item.visitId == null ? null : visitsById[item.visitId];
        final bubble = ChatMessageBubble(
          message: item,
          isMine: isMine,
          peerName: conversation?.peer.fullName,
          peerImageUrl: conversation?.peer.profileImageUrl,
          visit: visit,
          onConfirmVisit: widget.onConfirmVisit,
          onRescheduleVisit: widget.onRescheduleVisit,
        );
        // Optimistic messages (negative ids) render dimmed until confirmed.
        if (item.id < 0) {
          return Opacity(opacity: 0.6, child: bubble);
        }
        return bubble;
      },
    );
  }
}
