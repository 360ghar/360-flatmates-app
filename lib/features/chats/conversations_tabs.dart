part of 'conversations_page.dart';

/// Column count and cell shape for the Likes You / You Liked profile grid.
///
/// The count follows the viewport breakpoints ([AppBreakpoints.profileGridColumns]
/// — 2 on a phone, 3 from 600 dp, 4 from 900 dp, so the 951 dp open foldable
/// gets 4) and the ratio is derived from [gridWidth], the width the grid is
/// actually given, *using the same count*.
///
/// The two have to agree: the ratio exists to keep the photo square above the
/// 48 dp Match button, and that depends on the real cell width. A ratio
/// computed for 2 columns while the delegate lays out 4 would make every cell
/// the wrong shape.
({int columns, double childAspectRatio}) _likesGridMetrics(
  BuildContext context,
  double gridWidth,
) {
  final columns = AppBreakpoints.profileGridColumns(
    MediaQuery.sizeOf(context).width,
  );
  final itemWidth = (gridWidth - AppSpacing.md * (columns - 1)) / columns;
  // Match CTA (48 dp button + 8 dp gap), scaled with the text size.
  final belowPhotoReserve = AppSpacing.scaled(context, AppSpacing.s56);
  return (
    columns: columns,
    childAspectRatio: itemWidth / (itemWidth + belowPhotoReserve),
  );
}

/// Likes grid: one grid for the loaded lists and the skeleton, so the two can
/// never disagree about the column count and the page does not reflow the
/// moment data arrives.
class _LikesGrid extends StatelessWidget {
  const _LikesGrid({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _likesGridMetrics(context, constraints.maxWidth);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: metrics.columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: metrics.childAspectRatio,
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}

class _LikesTab extends StatelessWidget {
  const _LikesTab({
    required this.likes,
    required this.matchingLikeIds,
    required this.onRetry,
    required this.onMatchTap,
    required this.onLoadMore,
  });

  final AsyncValue<CursorListState<IncomingLikeModel>> likes;
  final Set<int> matchingLikeIds;
  final VoidCallback onRetry;
  final ValueChanged<IncomingLikeModel> onMatchTap;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);

    return FlatmatesAsyncView<CursorListState<IncomingLikeModel>>(
      value: likes,
      onRetry: onRetry,
      loading: const _LikesGridLoading(),
      isEmpty: (state) => state.items.isEmpty,
      empty: FlatmatesEmptyState(
        title: locale.noLikesYet,
        subtitle: locale.keepSwipingToFindMatches,
        icon: Icons.favorite_border_rounded,
        padHorizontally: false,
        minHeight: 320,
      ),
      data: (state) => Column(
        children: [
          _LikesGrid(
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return FlatmatesProfileGridCard(
                key: ValueKey('incoming_like_${item.id}'),
                name: item.peer.fullName,
                location: _locationForPeer(item.peer),
                profession: _professionForPeer(locale, item.peer),
                matchPercentage: item.peer.matchPercentage,
                imageUrl: item.peer.profileImageUrl,
                matchButtonLabel: locale.matchAction,
                onTap: () => FlatmateProfileSheet.show(
                  context: context,
                  userId: item.peer.id,
                  nameFallback: item.peer.fullName,
                ),
                onMatchTap: matchingLikeIds.contains(item.id)
                    ? null
                    : () => onMatchTap(item),
              );
            },
          ),
          if (state.hasMore)
            _LoadMoreFooter(
              isLoadingMore: state.isLoadingMore,
              onLoadMore: onLoadMore,
            ),
        ],
      ),
    );
  }
}

class _LikedTab extends StatelessWidget {
  const _LikedTab({
    required this.likes,
    required this.onRetry,
    required this.onLoadMore,
  });

  final AsyncValue<CursorListState<OutgoingLikeModel>> likes;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);

    return FlatmatesAsyncView<CursorListState<OutgoingLikeModel>>(
      value: likes,
      onRetry: onRetry,
      loading: const _LikesGridLoading(),
      isEmpty: (state) => state.items.isEmpty,
      empty: FlatmatesEmptyState(
        title: locale.noLikedYet,
        subtitle: locale.keepSwipingToFindMatches,
        icon: Icons.favorite_rounded,
        padHorizontally: false,
        minHeight: 320,
      ),
      data: (state) {
        final cards = <Widget>[];
        for (final item in state.items) {
          if (item.targetType == SwipeTargetType.property &&
              item.property != null) {
            final property = item.property!;
            final location = [
              if (property.locality != null &&
                  property.locality!.trim().isNotEmpty)
                property.locality!.trim(),
              if (property.city != null && property.city!.trim().isNotEmpty)
                property.city!.trim(),
            ].join(', ');
            cards.add(
              FlatmatesProfileGridCard(
                key: ValueKey('outgoing_like_property_${property.id}'),
                name: property.title,
                location: location,
                profession: locale.monthlyRentLabel(
                  FlatmatesPriceText.formatRupee(property.monthlyRent.round()),
                ),
                matchPercentage: null,
                imageUrl: property.effectiveMainImageUrl,
                matchButtonLabel: '',
                onTap: () => context.push('/flat-details/${property.id}'),
                onMatchTap: null,
              ),
            );
            continue;
          }
          final peer = item.peer;
          if (peer == null) continue;
          cards.add(
            FlatmatesProfileGridCard(
              key: ValueKey('outgoing_like_${item.id}'),
              name: peer.fullName,
              location: _locationForPeer(peer),
              profession: _professionForPeer(locale, peer),
              matchPercentage: peer.matchPercentage,
              imageUrl: peer.profileImageUrl,
              matchButtonLabel: '',
              onTap: () => FlatmateProfileSheet.show(
                context: context,
                userId: peer.id,
                nameFallback: peer.fullName,
              ),
              onMatchTap: null,
            ),
          );
        }

        if (cards.isEmpty) {
          return FlatmatesEmptyState(
            title: locale.noLikedYet,
            subtitle: locale.keepSwipingToFindMatches,
            icon: Icons.favorite_rounded,
            padHorizontally: false,
            minHeight: 320,
          );
        }

        return Column(
          children: [
            _LikesGrid(
              itemCount: cards.length,
              itemBuilder: (context, index) => cards[index],
            ),
            if (state.hasMore)
              _LoadMoreFooter(
                isLoadingMore: state.isLoadingMore,
                onLoadMore: onLoadMore,
              ),
          ],
        );
      },
    );
  }
}

class _ChatsTab extends StatelessWidget {
  const _ChatsTab({
    required this.conversations,
    required this.onRetry,
    required this.onLoadMore,
    this.loading,
  });

  final AsyncValue<CursorListState<ConversationSummaryModel>> conversations;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return FlatmatesAsyncView<CursorListState<ConversationSummaryModel>>(
      value: conversations,
      onRetry: onRetry,
      loading: loading,
      isEmpty: (state) => state.items.isEmpty,
      empty: FlatmatesEmptyState(
        title: locale.noConversations,
        subtitle: locale.startChatWithMatch,
        icon: Icons.chat_bubble_outline_rounded,
        padHorizontally: false,
        minHeight: 320,
      ),
      data: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, item) in state.items.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ConversationCard(
                cardKey: Key('conversation_card_$index'),
                item: item,
                onTap: () => context.push('/chats/${item.id}', extra: item),
              ),
            ),
          if (state.hasMore)
            _LoadMoreFooter(
              isLoadingMore: state.isLoadingMore,
              onLoadMore: onLoadMore,
            ),
        ],
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: FlatmatesButton.tertiary(
          label: locale.loadMoreCta,
          onPressed: onLoadMore,
          icon: Icons.expand_more_rounded,
        ),
      ),
    );
  }
}

/// Likes grid placeholder: paper-2 cards with paper-deep bones, laid out with
/// the same [_likesGridMetrics] as the real grid so the page does not reflow on
/// load.
class _LikesGridLoading extends StatelessWidget {
  const _LikesGridLoading();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bone = AppSemanticColors.paperDeepFor(brightness);

    Widget line(double height, double? width) => Container(
      height: height,
      width: width,
      decoration: BoxDecoration(color: bone, borderRadius: AppRadius.xsBorder),
    );

    return _LikesGrid(
      itemCount: 4,
      itemBuilder: (context, index) => FlatmatesCard(
        backgroundColor: AppSemanticColors.paper2For(brightness),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bone,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.card),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  line(12, double.infinity),
                  const SizedBox(height: AppSpacing.sm),
                  line(10, 80),
                ],
              ),
            ),
          ],
        ),
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
