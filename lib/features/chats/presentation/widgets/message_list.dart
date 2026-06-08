import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_empty_state.dart';
import '../../../shared/presentation/flatmates_error_state.dart';
import '../../../shared/presentation/flatmates_skeleton.dart';
import '../../chats_repository.dart';
import '../../../visits/visits_repository.dart';
import 'chat_message_bubble.dart';

class MessageList extends StatelessWidget {
  const MessageList({
    required this.messagesAsync,
    required this.currentUserId,
    required this.conversation,
    required this.visitsAsync,
    required this.onConfirmVisit,
    required this.onRescheduleVisit,
    super.key,
  });

  final AsyncValue<List<ChatMessage>> messagesAsync;
  final int currentUserId;
  final ConversationSummaryModel? conversation;
  final AsyncValue<List<VisitItem>> visitsAsync;
  final ValueChanged<VisitItem> onConfirmVisit;
  final ValueChanged<VisitItem> onRescheduleVisit;

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

    return messagesAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return FlatmatesEmptyState(
            title: locale.startAConversation,
            subtitle: locale.sayHelloOrIcebreaker,
            icon: Icons.chat_bubble_outline_rounded,
          );
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
            final visit = item.visitId == null
                ? null
                : visitsById[item.visitId];
            return ChatMessageBubble(
              message: item,
              isMine: isMine,
              peerName: conversation?.peer.fullName,
              peerImageUrl: conversation?.peer.profileImageUrl,
              visit: visit,
              onConfirmVisit: onConfirmVisit,
              onRescheduleVisit: onRescheduleVisit,
            );
          },
        );
      },
      loading: () => const FlatmatesSkeleton.chatMessages(),
      error: (error, _) =>
          FlatmatesErrorState(message: locale.couldNotLoadMessages),
    );
  }
}
