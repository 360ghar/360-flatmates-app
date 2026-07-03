import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chats_repository.dart';

/// Generic controller base for cursor-paginated list endpoints.
///
/// Subclasses override [fetchPage] to call their repository's
/// `fetchXPage(cursor: ...)` method. The state machine is intentionally
/// minimal: `load()` always starts fresh, `loadMore()` appends the next
/// page. Both are safe against re-entry (re-entrant calls are dropped).
///
/// The controller only depends on `ref` (no `family` arg) so the same
/// instance can be reused across screen mounts; `refresh()` resets state
/// without disposing the provider.
abstract class CursorListController<T>
    extends Notifier<AsyncValue<CursorListState<T>>> {
  /// Current cursor for the next page. Null means "first page" or "end of
  /// stream" — distinguished by [hasMore].
  String? _nextCursor;
  bool _hasMore = true;
  bool _loadInFlight = false;
  bool _refreshAfterCurrentLoad = false;
  final List<T> _optimisticItems = <T>[];

  /// Override to call the concrete repository's cursor-paginated endpoint.
  Future<({List<T> items, String? nextCursor, bool hasMore})> fetchPage({
    String? cursor,
  });

  @override
  AsyncValue<CursorListState<T>> build() {
    Future<void>.microtask(() {
      if (!_loadInFlight && state.isLoading) {
        unawaited(load());
      }
    });
    return const AsyncValue.loading();
  }

  /// Loads the first page. Subsequent calls while a load is in flight are
  /// dropped — callers needing a forced refresh should call [refresh].
  Future<void> load() async {
    if (_loadInFlight) {
      _refreshAfterCurrentLoad = true;
      return;
    }

    do {
      _refreshAfterCurrentLoad = false;
      _loadInFlight = true;
      final current = state.valueOrNull;
      state = current == null
          ? const AsyncValue.loading()
          : AsyncValue.data(current.copyWith(clearError: true));
      _nextCursor = null;
      _hasMore = true;
      try {
        final page = await fetchPage(cursor: null);
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        state = AsyncValue.data(
          CursorListState<T>(
            items: _mergeOptimisticItems(page.items),
            hasMore: page.hasMore,
          ),
        );
      } catch (e, st) {
        if (current == null) {
          state = AsyncValue.error(e, st);
        } else {
          state = AsyncValue.data(current.copyWith(error: e));
        }
      } finally {
        _loadInFlight = false;
      }
    } while (_refreshAfterCurrentLoad);
  }

  /// Appends the next page if more pages exist. Drops re-entrant calls.
  Future<void> loadMore() async {
    if (_loadInFlight || !_hasMore) return;
    final current = state.valueOrNull;
    if (current == null) return;
    _loadInFlight = true;
    state = AsyncValue.data(
      current.copyWith(isLoadingMore: true, clearError: true),
    );
    try {
      final page = await fetchPage(cursor: _nextCursor);
      _nextCursor = page.nextCursor;
      _hasMore = page.hasMore;
      // Read the latest state at write time rather than the pre-await
      // snapshot, so concurrent mutations during the request (e.g. an
      // optimistic removal via removeOptimistically) are not clobbered.
      final latest = state.valueOrNull ?? current;
      final mergedItems = _mergeOptimisticItems([
        ...latest.items,
        ...page.items,
      ]);
      state = AsyncValue.data(
        latest.copyWith(
          items: mergedItems,
          isLoadingMore: false,
          hasMore: page.hasMore,
        ),
      );
    } catch (e, st) {
      // Preserve the existing items so a transient error on a load-more
      // request doesn't blow away the list the user is browsing.
      final latest = state.valueOrNull ?? current;
      // Also surface to listeners that read .error directly.
      state = AsyncValue.error(e, st);
      // Restore the items + error on top so the UI keeps the list.
      state = AsyncValue.data(latest.copyWith(isLoadingMore: false, error: e));
    } finally {
      _loadInFlight = false;
      if (_refreshAfterCurrentLoad) {
        unawaited(load());
      }
    }
  }

  /// Drops the cache and reloads the first page.
  Future<void> refresh() async {
    _refreshAfterCurrentLoad = true;
    await load();
  }

  /// Inserts or promotes [item] immediately while a background refresh
  /// reconciles the real server id/order.
  void upsertOptimistically(T item) {
    _optimisticItems.removeWhere((existing) => matchesItem(existing, item));
    _optimisticItems.insert(0, item);
    final current = state.valueOrNull ?? CursorListState<T>();
    final items = current.items
        .where((existing) => !matchesItem(existing, item))
        .toList(growable: false);
    state = AsyncValue.data(current.copyWith(items: [item, ...items]));
  }

  /// Optimistically remove [item] from the rendered list (e.g. after the
  /// user blocks or unmatches a conversation). The caller is still
  /// responsible for the corresponding API mutation + provider
  /// invalidation; this just keeps the UI in sync with the mutation
  /// result without waiting for a network round-trip.
  void removeOptimistically(T item) {
    removeWhereOptimistically((existing) => matchesItem(existing, item));
  }

  /// Optimistically removes every rendered and pending optimistic item matching
  /// [test].
  void removeWhereOptimistically(bool Function(T item) test) {
    _optimisticItems.removeWhere(test);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      current.copyWith(
        items: current.items.where((existing) => !test(existing)).toList(),
      ),
    );
  }

  /// Subclasses can override to define equality semantics for optimistic
  /// updates (e.g. by id or peer id).
  bool matchesItem(T a, T b) {
    return identical(a, b) || a.toString() == b.toString();
  }

  List<T> _mergeOptimisticItems(List<T> serverItems) {
    if (_optimisticItems.isEmpty) return serverItems;

    final merged = [...serverItems];
    final pending = <T>[];
    for (final optimistic in _optimisticItems) {
      final serverIndex = merged.indexWhere(
        (server) => matchesItem(server, optimistic),
      );
      if (serverIndex == -1) {
        pending.add(optimistic);
      } else {
        final serverItem = merged.removeAt(serverIndex);
        merged.insert(0, serverItem);
      }
    }
    _optimisticItems
      ..clear()
      ..addAll(pending);

    for (final optimistic in pending.reversed) {
      merged.removeWhere((server) => matchesItem(server, optimistic));
      merged.insert(0, optimistic);
    }
    return merged;
  }
}

/// Holds the rendered items plus the loading flags used by
/// [CursorListController]. Exposed as a typed record-style class so it
/// composes cleanly with `FlatmatesAsyncView` (which expects an
/// `AsyncValue<T>`).
class CursorListState<T> {
  const CursorListState({
    this.items = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<T> items;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  bool get hasError => error != null;

  CursorListState<T> copyWith({
    List<T>? items,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return CursorListState<T>(
      items: items ?? this.items,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Conversation / like controllers
// ---------------------------------------------------------------------------

class ConversationsListController
    extends CursorListController<ConversationSummaryModel> {
  @override
  Future<
    ({List<ConversationSummaryModel> items, String? nextCursor, bool hasMore})
  >
  fetchPage({String? cursor}) async {
    return ref
        .read(chatsRepositoryProvider)
        .fetchConversationsPage(cursor: cursor);
  }
}

class IncomingLikesController extends CursorListController<IncomingLikeModel> {
  @override
  Future<({List<IncomingLikeModel> items, String? nextCursor, bool hasMore})>
  fetchPage({String? cursor}) async {
    return ref
        .read(chatsRepositoryProvider)
        .fetchIncomingLikesPage(cursor: cursor);
  }

  void removePeerOptimistically(int peerId) {
    removeWhereOptimistically((like) => like.peer.id == peerId);
  }

  @override
  bool matchesItem(IncomingLikeModel a, IncomingLikeModel b) {
    return a.peer.id == b.peer.id;
  }
}

class OutgoingLikesController extends CursorListController<IncomingLikeModel> {
  @override
  Future<({List<IncomingLikeModel> items, String? nextCursor, bool hasMore})>
  fetchPage({String? cursor}) async {
    return ref
        .read(chatsRepositoryProvider)
        .fetchOutgoingLikesPage(cursor: cursor);
  }

  void upsertOutgoingLike(IncomingLikeModel like) {
    upsertOptimistically(like);
  }

  @override
  bool matchesItem(IncomingLikeModel a, IncomingLikeModel b) {
    return a.peer.id == b.peer.id;
  }
}

final conversationsListControllerProvider =
    NotifierProvider<
      ConversationsListController,
      AsyncValue<CursorListState<ConversationSummaryModel>>
    >(ConversationsListController.new);

final incomingLikesListControllerProvider =
    NotifierProvider<
      IncomingLikesController,
      AsyncValue<CursorListState<IncomingLikeModel>>
    >(IncomingLikesController.new);

final outgoingLikesListControllerProvider =
    NotifierProvider<
      OutgoingLikesController,
      AsyncValue<CursorListState<IncomingLikeModel>>
    >(OutgoingLikesController.new);

/// After a block/unmatch, the conversation list + like tabs must drop the
/// affected entries without a full reload. This helper invalidates the
/// shared cursor controllers and immediately reloads them so the tabs do
/// not stay stuck in [AsyncLoading].
///
/// Accepts a Riverpod [Ref] so it can be called from controllers (where
/// only `ref` is available, not `WidgetRef`).
Future<void> invalidateChatListControllers(Ref ref) async {
  ref.invalidate(conversationsListControllerProvider);
  ref.invalidate(incomingLikesListControllerProvider);
  ref.invalidate(outgoingLikesListControllerProvider);
  await ref.read(conversationsListControllerProvider.notifier).load();
  await ref.read(incomingLikesListControllerProvider.notifier).load();
  await ref.read(outgoingLikesListControllerProvider.notifier).load();
}
