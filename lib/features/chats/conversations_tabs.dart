part of 'conversations_page.dart';

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
        duration: AppMotion.buttonPress,
        curve: AppMotion.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Shared 2-column aspect ratio for Likes You / You Liked profile grid cards.
///
/// Meta is overlaid on the photo; only the Match CTA (when present) sits
/// below — reserve ~52 logical px so the button does not crush the image.
double _likesGridChildAspectRatio(BuildContext context) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  // Match hub ListView horizontal gutter (AppSpacing.screen on each side).
  const padding = AppSpacing.screen * 2;
  const belowPhotoReserve = 52.0;
  final gridWidth = screenWidth - padding;
  final itemWidth = (gridWidth - AppSpacing.md) / 2;
  return itemWidth / (itemWidth + belowPhotoReserve);
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
    final childAspectRatio = _likesGridChildAspectRatio(context);

    return FlatmatesAsyncView<CursorListState<IncomingLikeModel>>(
      value: likes,
      onRetry: onRetry,
      loading: const _InboxHubLoading(variant: _InboxHubLoadingVariant.grid),
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return FlatmatesProfileGridCard(
                key: ValueKey('incoming_like_${item.id}'),
                name: item.peer.fullName,
                age: item.peer.age,
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
    final childAspectRatio = _likesGridChildAspectRatio(context);

    return FlatmatesAsyncView<CursorListState<OutgoingLikeModel>>(
      value: likes,
      onRetry: onRetry,
      loading: const _InboxHubLoading(variant: _InboxHubLoadingVariant.grid),
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
          if (item.targetType == 'property' && item.property != null) {
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
                  property.monthlyRent.toStringAsFixed(0),
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
              age: peer.age,
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: childAspectRatio,
              ),
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
        child: TextButton.icon(
          onPressed: onLoadMore,
          icon: const Icon(Icons.expand_more_rounded),
          label: Text(locale.loadMoreCta),
        ),
      ),
    );
  }
}

/// High-contrast loading chrome for soft list-hub pages (Inbox tabs).
///
/// Default [FlatmatesSkeleton.list] bones blend into `surfaceSoft` page bg;
/// these white cards keep loading state obvious.
enum _InboxHubLoadingVariant { list, grid }

class _InboxHubLoading extends StatelessWidget {
  const _InboxHubLoading({required this.variant});

  final _InboxHubLoadingVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final cardBg = AppSemanticColors.surfaceFor(brightness);
    final bone = brightness == Brightness.dark
        ? AppSemanticColors.darkHairline
        : AppSemanticColors.hairline;

    if (variant == _InboxHubLoadingVariant.grid) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.72,
        children: List.generate(
          4,
          (_) => FlatmatesCard(
            backgroundColor: cardBg,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: bone.withValues(alpha: 0.55),
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
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: bone.withValues(alpha: 0.7),
                          borderRadius: AppRadius.xsBorder,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        height: 10,
                        width: 80,
                        decoration: BoxDecoration(
                          color: bone.withValues(alpha: 0.5),
                          borderRadius: AppRadius.xsBorder,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 3 ? 0 : AppSpacing.md),
          child: FlatmatesCard(
            backgroundColor: cardBg,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bone.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: 140,
                        decoration: BoxDecoration(
                          color: bone.withValues(alpha: 0.7),
                          borderRadius: AppRadius.xsBorder,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        height: 10,
                        width: 100,
                        decoration: BoxDecoration(
                          color: bone.withValues(alpha: 0.5),
                          borderRadius: AppRadius.xsBorder,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
