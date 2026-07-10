import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_error_state.dart';
import '../../../shared/presentation/flatmates_skeleton.dart';
import '../../application/messages_controller.dart';
import '../../chats_repository.dart';
import '../../../visits/visits_repository.dart';
import '../../../shared/presentation/flatmates_trust_badge.dart';
import 'chat_message_bubble.dart';

class MessageList extends ConsumerStatefulWidget {
  const MessageList({
    required this.messagesState,
    required this.currentUserId,
    required this.conversation,
    required this.visitsAsync,
    required this.onConfirmVisit,
    required this.onRescheduleVisit,
    required this.conversationId,
    super.key,
  });

  final MessagesState messagesState;
  final int currentUserId;
  final ConversationSummaryModel? conversation;
  final AsyncValue<List<VisitItem>> visitsAsync;
  final ValueChanged<VisitItem> onConfirmVisit;
  final ValueChanged<VisitItem> onRescheduleVisit;

  /// Conversation id used to drive the cursor-paginated `loadOlder()`
  /// trigger when the user scrolls toward the top of the thread.
  final int conversationId;

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList>
    with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  /// Triggers an older-page load when the user scrolls near the top of the
  /// thread. Backed by cursor pagination in [MessagesController.loadOlder].
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 80) {
      // Defer to a microtask so a build cycle doesn't observe a state
      // mutation triggered from within itself.
      Future.microtask(() {
        if (!mounted) return;
        ref
            .read(messagesControllerProvider(widget.conversationId).notifier)
            .loadOlder();
      });
    }
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
        widget.conversationId != oldWidget.conversationId;
    if (conversationChanged) {
      _lastMessageCount = count;
      _scrollToBottom(animated: false);
    } else if (count > _lastMessageCount) {
      // Older messages prepended (loadOlder): restore the user's previous
      // reading position so the viewport does not jump. Newest arrivals
      // (live, optimistic, refetch) still pin to the bottom — detected by
      // checking if a NEW message arrived (last item id changed).
      final oldMessages = oldWidget.messagesState.displayMessages;
      final currentMessages = widget.messagesState.displayMessages;
      final oldWidgetLastId = oldMessages.isEmpty ? null : oldMessages.last.id;
      final currentLastId = currentMessages.isEmpty
          ? null
          : currentMessages.last.id;
      if (oldWidgetLastId != null &&
          currentLastId != null &&
          currentLastId != oldWidgetLastId) {
        _scrollToBottom(animated: _lastMessageCount > 0);
      } else if (_scrollController.hasClients) {
        // Older messages were inserted at index 0; preserve the reading
        // position by anchoring on the previously first item.
        final previousFirstId = oldMessages.isEmpty
            ? null
            : oldMessages.first.id;
        if (previousFirstId != null) {
          final newIndex = currentMessages.indexWhere(
            (m) => m.id == previousFirstId,
          );
          // The inserted messages must come strictly before the previously
          // first item; if not, the merge re-ordered things and a bottom
          // anchor is safer.
          if (newIndex > 0) {
            final delta = newIndex * _estimatedBubbleHeight;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_scrollController.hasClients) return;
              _scrollController.jumpTo(_scrollController.offset + delta);
            });
          }
        }
      }
      _lastMessageCount = count;
    }
  }

  void _scrollToBottom({required bool animated}) {
    _scheduleScrollToBottom(animated: animated, attempts: 3);
  }

  void _scheduleScrollToBottom({
    required bool animated,
    required int attempts,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: AppMotion.pageTransition,
          curve: AppMotion.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
      // ListView.builder can underestimate maxScrollExtent until all items
      // are laid out; retry in the next frame if the extent grows.
      if (attempts > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scrollController.hasClients) return;
          final newTarget = _scrollController.position.maxScrollExtent;
          if (newTarget > target) {
            _scheduleScrollToBottom(animated: animated, attempts: attempts - 1);
          }
        });
      }
    });
  }

  bool _isMessageFromToday(DateTime createdAt) {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }

  /// Approximate height of a chat bubble; used to nudge the scroll offset
  /// when older messages are prepended so the user's reading position is
  /// approximately preserved. Exact pixels aren't required — the goal is to
  /// keep the same bubble anchored rather than snapping to the new top.
  static const double _estimatedBubbleHeight = 64;

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
      return _ChatEmptyCard(
        title: locale.noMessagesYet,
        subtitle: locale.noMessagesYetHint,
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

    // The leading 1-cell "load older" header doubles as the cursor-driven
    // scroll trigger and as the visible spinner when an older page is in
    // flight. When the server has confirmed there is no more history, we
    // render a muted "no more messages" cell instead.
    final leadingCells = <Widget>[
      if (messagesState.isLoadingOlder)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        )
      else if (!messagesState.hasMoreOlder)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            children: [
              FlatmatesTrustBadge(
                label: locale.messagesArePrivate,
                variant: FlatmatesTrustBadgeVariant.privacy,
                compact: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                locale.startOfConversation,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppSemanticColors.textSecondaryFor(theme.brightness),
                ),
              ),
            ],
          ),
        )
      else
        const SizedBox.shrink(),
    ];

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      itemCount:
          leadingCells.length + items.length + (showTodayDivider ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < leadingCells.length) {
          return leadingCells[index];
        }
        final shiftedIndex = index - leadingCells.length;
        if (showTodayDivider && shiftedIndex == todayDividerIndex) {
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
            ? (shiftedIndex < todayDividerIndex
                  ? shiftedIndex
                  : shiftedIndex - 1)
            : shiftedIndex;
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

/// Telegram-style empty-chat placeholder: a soft-pink rounded card, centered
/// in the available space and scrollable so it never overflows when the
/// viewport shrinks (keyboard/emoji picker open). Sized to content only.
class _ChatEmptyCard extends StatelessWidget {
  const _ChatEmptyCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Container(
      width: 240,
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8ED),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppSemanticColors.textPrimaryFor(Brightness.light),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppSemanticColors.textSecondaryFor(Brightness.light),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: card),
        ),
      ),
    );
  }
}
