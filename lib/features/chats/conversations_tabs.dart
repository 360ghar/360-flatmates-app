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
    final screenWidth = MediaQuery.of(context).size.width;
    const padding = AppSpacing.xl * 2;
    final gridWidth = screenWidth - padding;
    final itemWidth = (gridWidth - AppSpacing.md) / 2;
    final childAspectRatio = itemWidth / (itemWidth + 116);

    return FlatmatesAsyncView<CursorListState<IncomingLikeModel>>(
      value: likes,
      onRetry: onRetry,
      isEmpty: (state) => state.items.isEmpty,
      empty: FlatmatesEmptyState(
        title: locale.noLikesYet,
        subtitle: locale.keepSwipingToFindMatches,
        icon: Icons.favorite_border_rounded,
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
                blurImage: true,
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

  final AsyncValue<CursorListState<IncomingLikeModel>> likes;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    const padding = AppSpacing.xl * 2;
    final gridWidth = screenWidth - padding;
    final itemWidth = (gridWidth - AppSpacing.md) / 2;
    final childAspectRatio = itemWidth / (itemWidth + 72);

    return FlatmatesAsyncView<CursorListState<IncomingLikeModel>>(
      value: likes,
      onRetry: onRetry,
      isEmpty: (state) => state.items.isEmpty,
      empty: FlatmatesEmptyState(
        title: locale.noLikedYet,
        subtitle: locale.keepSwipingToFindMatches,
        icon: Icons.favorite_rounded,
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
                key: ValueKey('outgoing_like_${item.id}'),
                name: item.peer.fullName,
                age: item.peer.age,
                location: _locationForPeer(item.peer),
                profession: _professionForPeer(locale, item.peer),
                matchPercentage: item.peer.matchPercentage,
                imageUrl: item.peer.profileImageUrl,
                matchButtonLabel: '',
                onTap: () => FlatmateProfileSheet.show(
                  context: context,
                  userId: item.peer.id,
                  nameFallback: item.peer.fullName,
                ),
                onMatchTap: null,
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
      ),
      data: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, item) in state.items.indexed)
            Padding(
              key: ValueKey('conversation_${item.id}'),
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Semantics(
                identifier: 'conversation_card_$index',
                child: ConversationCard(
                  item: item,
                  onTap: () => context.push('/chats/${item.id}', extra: item),
                ),
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
