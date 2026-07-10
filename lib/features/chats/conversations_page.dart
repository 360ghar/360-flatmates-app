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
import '../discover/application/discover_feed_controller.dart';
import '../discover/presentation/widgets/discover_listing_card.dart';
import '../discover/presentation/widgets/flatmate_profile_sheet.dart';
import '../shared/presentation/components.dart';
import '../swipe/match_qna_nudge.dart';
import 'application/chat_actions_controller.dart';
import 'application/cursor_list_controller.dart';
import 'chats_repository.dart';
import 'presentation/widgets/conversation_card.dart';

part 'conversations_tabs.dart';

/// Overrides the tab coming from the route's `?tab=` query parameter once the
/// user switches tabs manually. Reset to null when a new initialTab arrives.
final _conversationsTabOverrideProvider = StateProvider<String?>((ref) => null);
final _matchingLikeIdsProvider = StateProvider<Set<int>>((ref) => {});

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key, this.initialTab = 'chats'});

  final String initialTab;

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  static const double _kBottomNavOffset = 120;

  @override
  void initState() {
    super.initState();
    // Prime each tab's controller so the first paint already has data and
    // switching tabs is instant.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(conversationsListControllerProvider.notifier).load();
      ref.read(incomingLikesListControllerProvider.notifier).load();
      ref.read(outgoingLikesListControllerProvider.notifier).load();
    });
  }

  @override
  void didUpdateWidget(ConversationsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      // Deferred: provider writes are not allowed while the tree is building.
      Future.microtask(() {
        if (!mounted) return;
        ref.read(_conversationsTabOverrideProvider.notifier).state = null;
      });
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(conversationsListControllerProvider.notifier).refresh(),
      ref.read(incomingLikesListControllerProvider.notifier).refresh(),
      ref.read(outgoingLikesListControllerProvider.notifier).refresh(),
    ]);
    // Keep the legacy providers in sync for any listener still on the old
    // FutureProvider surface (e.g. third-party widgets).
    ref.invalidate(conversationsProvider);
    ref.invalidate(incomingLikesProvider);
    ref.invalidate(outgoingLikesProvider);
  }

  Future<void> _onPropertyLike(OutgoingLikeModel like) async {
    final property = like.property;
    if (property == null) return;

    try {
      await ref
          .read(discoverFeedControllerProvider.notifier)
          .toggleLike(property.id, property: property);
    } catch (e) {
      debugPrint(
        'ConversationsPage._onPropertyLike failed for ${property.id}: $e',
      );
      if (mounted) {
        FlatmatesToast.error(
          context,
          AppLocalizations.of(context).actionFailedRetry,
        );
      }
    }
  }

  Future<void> _matchIncomingLike(IncomingLikeModel like) async {
    final matchingIds = ref.read(_matchingLikeIdsProvider);
    if (matchingIds.contains(like.id)) return;
    ref.read(_matchingLikeIdsProvider.notifier).state = {
      ...matchingIds,
      like.id,
    };

    final locale = AppLocalizations.of(context);
    try {
      final conversationId = await ref
          .read(chatActionsControllerProvider)
          .matchIncomingLike(
            peerId: like.peer.id,
            contextPropertyId: like.contextProperty?.id,
          );
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
    } catch (e) {
      debugPrint(
        'ConversationsPage._matchIncomingLike failed for like ${like.id}: $e',
      );
      if (mounted) _showMatchFailure(locale);
    } finally {
      if (mounted) {
        ref.read(_matchingLikeIdsProvider.notifier).state = {
          ...ref.read(_matchingLikeIdsProvider),
        }..remove(like.id);
      }
    }
  }

  void _showMatchFailure(AppLocalizations locale) {
    FlatmatesToast.error(context, locale.matchCreateFailed);
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsListControllerProvider);
    final incomingLikes = ref.watch(incomingLikesListControllerProvider);
    final outgoingLikes = ref.watch(outgoingLikesListControllerProvider);
    final tab =
        ref.watch(_conversationsTabOverrideProvider) ?? widget.initialTab;
    final matchingLikeIds = ref.watch(_matchingLikeIdsProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return FlatmatesScreen(
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
              selected: tab,
              onChanged: (v) =>
                  ref.read(_conversationsTabOverrideProvider.notifier).state =
                      v,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (tab == 'likes')
              _LikesTab(
                likes: incomingLikes,
                matchingLikeIds: matchingLikeIds,
                onRetry: () => ref
                    .read(incomingLikesListControllerProvider.notifier)
                    .refresh(),
                onLoadMore: () => ref
                    .read(incomingLikesListControllerProvider.notifier)
                    .loadMore(),
                onMatchTap: _matchIncomingLike,
              )
            else if (tab == 'liked')
              _LikedTab(
                likes: outgoingLikes,
                onRetry: () => ref
                    .read(outgoingLikesListControllerProvider.notifier)
                    .refresh(),
                onLoadMore: () => ref
                    .read(outgoingLikesListControllerProvider.notifier)
                    .loadMore(),
                onPropertyLike: _onPropertyLike,
              )
            else
              _ChatsTab(
                conversations: conversations,
                onRetry: () => ref
                    .read(conversationsListControllerProvider.notifier)
                    .refresh(),
                onLoadMore: () => ref
                    .read(conversationsListControllerProvider.notifier)
                    .loadMore(),
                loading: const FlatmatesSkeleton.conversationList(),
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
            const Icon(
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
                      fontWeight: AppTypography.titleMdWeight,
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
