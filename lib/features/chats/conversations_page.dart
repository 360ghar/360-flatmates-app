import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_async_view.dart';
import '../shared/presentation/flatmates_bottom_sheet.dart';
import '../shared/presentation/flatmates_card.dart';
import '../shared/presentation/flatmates_empty_state.dart';
import '../shared/presentation/flatmates_segmented_control.dart';
import '../shared/presentation/flatmates_ui.dart';
import '../swipe/match_qna_nudge.dart';
import 'chats_repository.dart';
import 'presentation/widgets/conversation_card.dart';

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  final Set<int> _matchingLikeIds = {};
  String _tab = 'likes';

  Future<void> _refresh() async {
    ref.invalidate(conversationsProvider);
    ref.invalidate(incomingLikesProvider);
    ref.invalidate(outgoingLikesProvider);
  }

  Future<void> _matchIncomingLike(IncomingLikeModel like) async {
    if (_matchingLikeIds.contains(like.id)) return;
    setState(() => _matchingLikeIds.add(like.id));

    final locale = AppLocalizations.of(context);
    try {
      final conversationId = await ref
          .read(chatsRepositoryProvider)
          .matchIncomingLike(
            peerId: like.peer.id,
            contextPropertyId: like.contextProperty?.id,
          );
      ref.invalidate(incomingLikesProvider);
      ref.invalidate(conversationsProvider);
      if (!mounted) return;
      if (conversationId == null) {
        _showMatchFailure(locale);
        return;
      }

      unawaited(context.push('/chats/$conversationId'));
      unawaited(
        Future<void>.delayed(AppMotion.matchCelebration, () {
          if (!mounted) return;
          FlatmatesBottomSheet.show(
            context: context,
            isScrollControlled: true,
            builder: (_) => MatchQnANudgeSheet(conversationId: conversationId),
          );
        }),
      );
    } catch (_) {
      if (mounted) _showMatchFailure(locale);
    } finally {
      if (mounted) setState(() => _matchingLikeIds.remove(like.id));
    }
  }

  void _showMatchFailure(AppLocalizations locale) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(locale.matchCreateFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    final incomingLikes = ref.watch(incomingLikesProvider);
    final outgoingLikes = ref.watch(outgoingLikesProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              120,
            ),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const FlatmatesLogo(compact: true),
                  const Spacer(),
                  Text(
                    locale.likesChatTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: AppTypography.displayWeight,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: AppSpacing.screen),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              FlatmatesSegmentedControl<String>(
                segmentKeys: const [
                  Key('chats_likes_tab'),
                  Key('chats_liked_tab'),
                  Key('chats_chats_tab'),
                ],
                segments: [
                  (
                    'likes',
                    locale.likesTabLabel,
                    Icons.favorite_border_rounded,
                  ),
                  (
                    'liked',
                    locale.likedTabLabel,
                    Icons.favorite_rounded,
                  ),
                  (
                    'chats',
                    locale.chatsTabLabel,
                    Icons.chat_bubble_outline_rounded,
                  ),
                ],
                selected: _tab,
                onChanged: (v) => setState(() => _tab = v),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_tab == 'likes')
                _LikesTab(
                  likes: incomingLikes,
                  matchingLikeIds: _matchingLikeIds,
                  onRetry: () => ref.invalidate(incomingLikesProvider),
                  onMatchTap: _matchIncomingLike,
                )
              else if (_tab == 'liked')
                _LikedTab(
                  likes: outgoingLikes,
                  onRetry: () => ref.invalidate(outgoingLikesProvider),
                )
              else
                _ChatsTab(
                  conversations: conversations,
                  onRetry: () => ref.invalidate(conversationsProvider),
                ),
              const SizedBox(height: AppSpacing.md),
              _buildSafetyBanner(context, theme, locale),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyBanner(
    BuildContext context,
    ThemeData theme,
    AppLocalizations locale,
  ) {
    return FlatmatesCard(
      margin: EdgeInsets.zero,
      borderRadius: AppRadius.mdBorder,
      backgroundColor: AppSemanticColors.coralSoftFor(
        theme.brightness,
      ).withValues(alpha: 0.4),
      onTap: () => context.push('/help-safety'),
      child: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            size: 22,
            color: AppSemanticColors.accent,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.safetyFirstTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.h3Weight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  locale.safetyFirstSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: AppTypography.captionSize,
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppSemanticColors.textSecondaryFor(theme.brightness),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _LikesTab extends StatelessWidget {
  const _LikesTab({
    required this.likes,
    required this.matchingLikeIds,
    required this.onRetry,
    required this.onMatchTap,
  });

  final AsyncValue<List<IncomingLikeModel>> likes;
  final Set<int> matchingLikeIds;
  final VoidCallback onRetry;
  final ValueChanged<IncomingLikeModel> onMatchTap;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return FlatmatesAsyncView<List<IncomingLikeModel>>(
      value: likes,
      onRetry: onRetry,
      empty: FlatmatesEmptyState(
        title: locale.noLikesYet,
        subtitle: locale.keepSwipingToFindMatches,
        icon: Icons.favorite_border_rounded,
      ),
      data: (items) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.75,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return FlatmatesProfileGridCard(
            key: ValueKey('incoming_like_${item.id}'),
            name: item.peer.fullName,
            age: item.peer.age,
            location: _locationForPeer(item.peer),
            profession: _professionForPeer(locale, item.peer),
            matchPercentage: item.peer.matchPercentage,
            imageUrl: item.peer.profileImageUrl,
            blurImage: true,
            matchButtonLabel: locale.matchAction,
            onMatchTap: matchingLikeIds.contains(item.id)
                ? null
                : () => onMatchTap(item),
          );
        },
      ),
    );
  }
}

class _LikedTab extends StatelessWidget {
  const _LikedTab({required this.likes, required this.onRetry});

  final AsyncValue<List<IncomingLikeModel>> likes;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return FlatmatesAsyncView<List<IncomingLikeModel>>(
      value: likes,
      onRetry: onRetry,
      empty: FlatmatesEmptyState(
        title: locale.noLikedYet,
        subtitle: locale.keepSwipingToFindMatches,
        icon: Icons.favorite_rounded,
      ),
      data: (items) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.68,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return FlatmatesProfileGridCard(
            key: ValueKey('outgoing_like_${item.id}'),
            name: item.peer.fullName,
            age: item.peer.age,
            location: _locationForPeer(item.peer),
            profession: _professionForPeer(locale, item.peer),
            matchPercentage: item.peer.matchPercentage,
            imageUrl: item.peer.profileImageUrl,
            matchButtonLabel: '',
            onMatchTap: null,
          );
        },
      ),
    );
  }
}

class _ChatsTab extends StatelessWidget {
  const _ChatsTab({required this.conversations, required this.onRetry});

  final AsyncValue<List<ConversationSummaryModel>> conversations;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return FlatmatesAsyncView<List<ConversationSummaryModel>>(
      value: conversations,
      onRetry: onRetry,
      empty: FlatmatesEmptyState(
        title: locale.noConversations,
        subtitle: locale.startChatWithMatch,
        icon: Icons.chat_bubble_outline_rounded,
      ),
      data: (items) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: ConversationCard(
                item: item,
                onTap: () => context.push('/chats/${item.id}', extra: item),
              ),
            ),
        ],
      ),
    );
  }
}

String _locationForPeer(ChatPeer peer) {
  return [
    if (peer.locality != null && peer.locality!.trim().isNotEmpty)
      peer.locality!.trim(),
    if (peer.city != null && peer.city!.trim().isNotEmpty) peer.city!.trim(),
  ].join(', ');
}

String _professionForPeer(AppLocalizations locale, ChatPeer peer) {
  final profession = peer.profession?.trim();
  if (profession != null && profession.isNotEmpty) return profession;
  final mode = peer.mode;
  return mode == null ? '' : localizedFlatmatesModeLabel(locale, mode);
}
