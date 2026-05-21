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
import '../shared/presentation/components.dart';
import '../swipe/match_qna_nudge.dart';
import 'chats_repository.dart';
import 'presentation/widgets/conversation_card.dart';

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  static const double _kBottomNavOffset = 120;
  final Set<int> _matchingLikeIds = {};
  String _tab = 'chats';

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

    return FlatmatesScreen(
      useSafeArea: true,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            _kBottomNavOffset,
          ),
          children: [
            const SizedBox(height: AppSpacing.md),
            FlatmatesSegmentedControl<String>(
              segmentKeys: const [
                Key('chats_chats_tab'),
                Key('chats_likes_tab'),
                Key('chats_liked_tab'),
              ],
              segments: [
                (
                  'chats',
                  locale.chatsTabLabel,
                  Icons.chat_bubble_outline_rounded,
                ),
                ('likes', locale.likesTabLabel, Icons.favorite_border_rounded),
                ('liked', locale.likedTabLabel, Icons.favorite_rounded),
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
    );
  }

  Widget _buildSafetyBanner(
    BuildContext context,
    ThemeData theme,
    AppLocalizations locale,
  ) {
    return _InteractivePressScale(
      child: FlatmatesCard(
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
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
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
      ),
    );
  }
}

/// Applies standard interactive scale animation to any child when pressed.
class _InteractivePressScale extends StatefulWidget {
  const _InteractivePressScale({required this.child});

  final Widget child;

  @override
  State<_InteractivePressScale> createState() => _InteractivePressScaleState();
}

class _InteractivePressScaleState extends State<_InteractivePressScale> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _scale = 0.97),
      onPointerUp: (_) => setState(() => _scale = 1.0),
      onPointerCancel: (_) => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: widget.child,
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
    final screenWidth = MediaQuery.of(context).size.width;
    const padding = AppSpacing.xl * 2;
    final gridWidth = screenWidth - padding;
    final itemWidth = (gridWidth - AppSpacing.md) / 2;
    // With match button, fixed elements height is ~116
    final totalHeight = itemWidth + 116;
    final childAspectRatio = itemWidth / totalHeight;

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
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: childAspectRatio,
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
    final screenWidth = MediaQuery.of(context).size.width;
    const padding = AppSpacing.xl * 2;
    final gridWidth = screenWidth - padding;
    final itemWidth = (gridWidth - AppSpacing.md) / 2;
    // Without match button, fixed elements height is ~72
    final totalHeight = itemWidth + 72;
    final childAspectRatio = itemWidth / totalHeight;

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
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: childAspectRatio,
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
