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

  /// Override to call the concrete repository's cursor-paginated endpoint.
  Future<({List<T> items, String? nextCursor, bool hasMore})> fetchPage({
    String? cursor,
  });

  @override
  AsyncValue<CursorListState<T>> build() {
    return const AsyncValue.loading();
  }

  /// Loads the first page. Subsequent calls while a load is in flight are
  /// dropped — callers needing a forced refresh should call [refresh].
  Future<void> load() async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = const AsyncValue.loading();
    _nextCursor = null;
    _hasMore = true;
    try {
      final page = await fetchPage(cursor: null);
      _nextCursor = page.nextCursor;
      _hasMore = page.hasMore;
      state = AsyncValue.data(
        CursorListState<T>(
          items: page.items,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _loadInFlight = false;
    }
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
      state = AsyncValue.data(
        current.copyWith(
          items: [...current.items, ...page.items],
          isLoadingMore: false,
          hasMore: page.hasMore,
        ),
      );
    } catch (e, st) {
      // Preserve the existing items so a transient error on a load-more
      // request doesn't blow away the list the user is browsing.
      state = AsyncValue.data(
        current.copyWith(isLoadingMore: false, error: e),
      );
      // Also surface to listeners that read .error directly.
      state = AsyncValue.error(e, st);
      // Restore the items + error on top so the UI keeps the list.
      state = AsyncValue.data(
        current.copyWith(isLoadingMore: false, error: e),
      );
    } finally {
      _loadInFlight = false;
    }
  }

  /// Drops the cache and reloads the first page.
  Future<void> refresh() async {
    await load();
  }

  /// Optimistically remove [item] from the rendered list (e.g. after the
  /// user blocks or unmatches a conversation). The caller is still
  /// responsible for the corresponding API mutation + provider
  /// invalidation; this just keeps the UI in sync with the mutation
  /// result without waiting for a network round-trip.
  void removeOptimistically(T item) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      current.copyWith(
        items: current.items.where((existing) => !_matches(existing, item)).toList(),
      ),
    );
  }

  /// Subclasses can override to define equality semantics for optimistic
  /// removal (e.g. by id).
  bool _matches(T a, T b) {
    return identical(a, b) || a.toString() == b.toString();
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
  Future<({List<ConversationSummaryModel> items, String? nextCursor, bool hasMore})>
      fetchPage({String? cursor}) async {
    return ref
        .read(chatsRepositoryProvider)
        .fetchConversationsPage(cursor: cursor);
  }
}

class IncomingLikesController
    extends CursorListController<IncomingLikeModel> {
  @override
  Future<({List<IncomingLikeModel> items, String? nextCursor, bool hasMore})>
      fetchPage({String? cursor}) async {
    return ref
        .read(chatsRepositoryProvider)
        .fetchIncomingLikesPage(cursor: cursor);
  }
}

class OutgoingLikesController
    extends CursorListController<IncomingLikeModel> {
  @override
  Future<({List<IncomingLikeModel> items, String? nextCursor, bool hasMore})>
      fetchPage({String? cursor}) async {
    return ref
        .read(chatsRepositoryProvider)
        .fetchOutgoingLikesPage(cursor: cursor);
  }
}

final conversationsListControllerProvider = NotifierProvider<
    ConversationsListController, AsyncValue<CursorListState<ConversationSummaryModel>>>(
  ConversationsListController.new,
);

final incomingLikesListControllerProvider = NotifierProvider<
    IncomingLikesController, AsyncValue<CursorListState<IncomingLikeModel>>>(
  IncomingLikesController.new,
);

final outgoingLikesListControllerProvider = NotifierProvider<
    OutgoingLikesController, AsyncValue<CursorListState<IncomingLikeModel>>>(
  OutgoingLikesController.new,
);

/// After a block/unmatch, the conversation list + like tabs must drop the
/// affected entries without a full reload. This helper invalidates the
/// shared cursor controllers so the next tab activation triggers a fresh
/// first-page fetch while preserving optimistic removal.
///
/// Accepts a Riverpod [Ref] so it can be called from controllers (where
/// only `ref` is available, not `WidgetRef`).
void invalidateChatListControllers(Ref ref) {
  ref.invalidate(conversationsListControllerProvider);
  ref.invalidate(incomingLikesListControllerProvider);
  ref.invalidate(outgoingLikesListControllerProvider);
}
