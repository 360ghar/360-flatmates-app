import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/mutable_notifier.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/gen/app_localizations.dart';
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
final _conversationsTabOverrideProvider =
    NotifierProvider<MutableNotifier<String?>, String?>(
      () => MutableNotifier(null),
    );
final _matchingLikeIdsProvider =
    NotifierProvider<MutableNotifier<Set<int>>, Set<int>>(
      () => MutableNotifier(const <int>{}),
    );

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key, this.initialTab = 'chats'});

  final String initialTab;

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  static const double _kBottomNavOffset = 120;

  @override
  void didUpdateWidget(ConversationsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      // Deferred: provider writes are not allowed while the tree is building.
      // Clearing the override re-selects the route tab; the matching list
      // controller is watched in build() and auto-loads on first create.
      Future.microtask(() {
        if (!mounted) return;
        ref.read(_conversationsTabOverrideProvider.notifier).set(null);
      });
    }
  }

  Future<void> _refresh() async {
    final tab =
        ref.read(_conversationsTabOverrideProvider) ?? widget.initialTab;
    // Refresh only the active tab — matches lazy watch policy below.
    if (tab == 'likes') {
      await ref.read(incomingLikesListControllerProvider.notifier).refresh();
      ref.invalidate(incomingLikesProvider);
    } else if (tab == 'liked') {
      await ref.read(outgoingLikesListControllerProvider.notifier).refresh();
      ref.invalidate(outgoingLikesProvider);
    } else {
      await ref.read(conversationsListControllerProvider.notifier).refresh();
      ref.invalidate(conversationsProvider);
    }
  }

  Future<void> _matchIncomingLike(IncomingLikeModel like) async {
    final matchingIds = ref.read(_matchingLikeIdsProvider);
    if (matchingIds.contains(like.id)) return;
    ref
        .read(_matchingLikeIdsProvider.notifier)
        .update((ids) => {...ids, like.id});

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
        ref.read(_matchingLikeIdsProvider.notifier).update((ids) {
          final next = {...ids};
          next.remove(like.id);
          return next;
        });
      }
    }
  }

  void _showMatchFailure(AppLocalizations locale) {
    FlatmatesToast.error(context, locale.matchCreateFailed);
  }

  @override
  Widget build(BuildContext context) {
    // Watch only the active tab's list controller. Watching all three would
    // create each Notifier and auto-load() every inbox open (CursorListController
    // primes itself in build()).
    final tab =
        ref.watch(_conversationsTabOverrideProvider) ?? widget.initialTab;
    final matchingLikeIds = ref.watch(_matchingLikeIdsProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final Widget tabBody;
    final bool tabIsEmpty;
    final bool tabHasData;
    if (tab == 'likes') {
      final incomingLikes = ref.watch(incomingLikesListControllerProvider);
      tabBody = _LikesTab(
        likes: incomingLikes,
        matchingLikeIds: matchingLikeIds,
        onRetry: () =>
            ref.read(incomingLikesListControllerProvider.notifier).refresh(),
        onLoadMore: () =>
            ref.read(incomingLikesListControllerProvider.notifier).loadMore(),
        onMatchTap: _matchIncomingLike,
      );
      tabIsEmpty =
          incomingLikes.hasValue &&
          (incomingLikes.valueOrNull?.items.isEmpty ?? true);
      tabHasData =
          incomingLikes.hasValue &&
          (incomingLikes.valueOrNull?.items.isNotEmpty ?? false);
    } else if (tab == 'liked') {
      final outgoingLikes = ref.watch(outgoingLikesListControllerProvider);
      tabBody = _LikedTab(
        likes: outgoingLikes,
        onRetry: () =>
            ref.read(outgoingLikesListControllerProvider.notifier).refresh(),
        onLoadMore: () =>
            ref.read(outgoingLikesListControllerProvider.notifier).loadMore(),
      );
      tabIsEmpty =
          outgoingLikes.hasValue &&
          (outgoingLikes.valueOrNull?.items.isEmpty ?? true);
      tabHasData =
          outgoingLikes.hasValue &&
          (outgoingLikes.valueOrNull?.items.isNotEmpty ?? false);
    } else {
      final conversations = ref.watch(conversationsListControllerProvider);
      tabBody = _ChatsTab(
        conversations: conversations,
        onRetry: () =>
            ref.read(conversationsListControllerProvider.notifier).refresh(),
        onLoadMore: () =>
            ref.read(conversationsListControllerProvider.notifier).loadMore(),
        // High-contrast white cards — conversationList bones blend into soft hub bg.
        loading: const _InboxHubLoading(variant: _InboxHubLoadingVariant.list),
      );
      tabIsEmpty =
          conversations.hasValue &&
          (conversations.valueOrNull?.items.isEmpty ?? true);
      tabHasData =
          conversations.hasValue &&
          (conversations.valueOrNull?.items.isNotEmpty ?? false);
    }

    // Hide the safety promo when the tab is empty so empty hubs don't look
    // like they already have content. Show it only alongside real list data.
    final showSafetyBanner = tabHasData && !tabIsEmpty;

    final listHubBg = AppSemanticColors.secondarySurfaceFor(theme.brightness);

    return FlatmatesScreen(
      backgroundColor: listHubBg,
      body: RefreshIndicator(
        color: AppSemanticColors.primary,
        backgroundColor: AppSemanticColors.surfaceFor(theme.brightness),
        onRefresh: _refresh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.base,
                AppSpacing.screen,
                _kBottomNavOffset,
              ),
              children: [
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
                    (
                      'likes',
                      locale.likesTabLabel,
                      Icons.favorite_border_rounded,
                    ),
                    ('liked', locale.likedTabLabel, Icons.favorite_rounded),
                  ],
                  selected: tab,
                  onChanged: (v) => ref
                      .read(_conversationsTabOverrideProvider.notifier)
                      .set(v),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (tabIsEmpty)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 160).clamp(
                        280.0,
                        double.infinity,
                      ),
                    ),
                    child: tabBody,
                  )
                else
                  tabBody,
                if (showSafetyBanner) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildSafetyBanner(context, theme, locale),
                ],
              ],
            );
          },
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
