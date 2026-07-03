import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chats/application/cursor_list_controller.dart';
import '../../chats/chats_repository.dart';
import '../../discover/discover_repository.dart';
import '../swipe_repository.dart';

/// Snapshot of the swipe deck state.
///
/// The deck renders at most `limit` profiles at a time. When the user nears
/// the end of the current deck, [SwipeDeckController.loadMore] is invoked
/// to fetch the next page using cursor pagination from the backend.
class SwipeDeckState {
  const SwipeDeckState({
    this.profiles = const [],
    this.currentIndex = 0,
    this.lastSwipedProfile,
    this.hasSwiped = false,
    this.nextCursor,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<SwipeProfile> profiles;
  final int currentIndex;
  final SwipeProfile? lastSwipedProfile;
  final bool hasSwiped;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  bool get hasError => error != null;
  bool get isEmpty => profiles.isEmpty && !isLoading;

  List<SwipeProfile> visibleProfiles(int? currentUserId) {
    return profiles.where((profile) => profile.id != currentUserId).toList();
  }

  SwipeProfile? currentProfile(int? currentUserId) {
    final visible = visibleProfiles(currentUserId);
    if (currentIndex < 0 || currentIndex >= visible.length) return null;
    return visible[currentIndex];
  }

  SwipeProfile? relativeProfile(int? currentUserId, int offset) {
    final visible = visibleProfiles(currentUserId);
    final index = currentIndex + offset;
    if (index < 0 || index >= visible.length) return null;
    return visible[index];
  }

  SwipeDeckState copyWith({
    List<SwipeProfile>? profiles,
    int? currentIndex,
    SwipeProfile? lastSwipedProfile,
    bool clearLastSwipedProfile = false,
    bool? hasSwiped,
    String? nextCursor,
    bool setNextCursorNull = false,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return SwipeDeckState(
      profiles: profiles ?? this.profiles,
      currentIndex: currentIndex ?? this.currentIndex,
      lastSwipedProfile: clearLastSwipedProfile
          ? null
          : (lastSwipedProfile ?? this.lastSwipedProfile),
      hasSwiped: hasSwiped ?? this.hasSwiped,
      nextCursor: setNextCursorNull ? null : (nextCursor ?? this.nextCursor),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SwipeDeckController extends Notifier<SwipeDeckState> {
  final Set<int> _swipedUserIds = {};
  bool _loadInFlight = false;
  int _filterVersion = 0;

  /// Whether the user has swiped at least one profile in the current deck.
  /// Lets the UI distinguish "end of deck" from "no profiles ever loaded".
  bool get hasSwiped => _swipedUserIds.isNotEmpty;

  @override
  SwipeDeckState build() {
    // Reload the deck whenever shared discover filters (location, radius,
    // move-in, ...) change from the swipe header or the explore page.
    ref.watch(discoverFiltersProvider);
    _filterVersion++;
    Future.microtask(() => _load());
    return const SwipeDeckState(isLoading: true);
  }

  Future<void> _load() async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = const SwipeDeckState(isLoading: true);
    final myVersion = _filterVersion;
    try {
      final filters = ref.read(discoverFiltersProvider);
      if (kDebugMode) {
        log('[SwipeDeck] Loading profiles, filters=$filters');
      } else {
        log('[SwipeDeck] Loading profiles');
      }
      final page = await ref
          .read(swipeRepositoryProvider)
          .fetchSwipeProfilesPage(filters: filters);
      if (kDebugMode) {
        log('[SwipeDeck] Loaded ${page.items.length} profiles');
      } else {
        log('[SwipeDeck] Loaded ${page.items.length} profiles');
      }
      final filtered = page.items
          .where((p) => !_swipedUserIds.contains(p.id))
          .toList();
      if (myVersion == _filterVersion) {
        state = state.copyWith(
          profiles: filtered,
          nextCursor: page.nextCursor,
          setNextCursorNull: page.nextCursor == null,
          hasMore: page.hasMore,
          isLoading: false,
          clearError: true,
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        log('[SwipeDeck] ERROR loading profiles: $e', error: e, stackTrace: st);
      } else {
        log('[SwipeDeck] ERROR loading profiles');
      }
      if (myVersion == _filterVersion) {
        state = state.copyWith(isLoading: false, error: e);
      }
    } finally {
      _loadInFlight = false;
    }
    if (myVersion != _filterVersion) {
      await _load();
    }
  }

  /// Appends the next page of profiles to the deck. Safe against re-entry:
  /// repeated calls while a load is in flight or after the stream has been
  /// fully drained are dropped.
  Future<void> loadMore() async {
    if (_loadInFlight || state.isLoadingMore || !state.hasMore) return;
    final cursor = state.nextCursor;
    if (cursor == null) return;
    _loadInFlight = true;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    final myVersion = _filterVersion;
    try {
      final filters = ref.read(discoverFiltersProvider);
      final page = await ref
          .read(swipeRepositoryProvider)
          .fetchSwipeProfilesPage(filters: filters, cursor: cursor);
      final existingIds = state.profiles.map((p) => p.id).toSet();
      final newProfiles = page.items
          .where(
            (p) =>
                !_swipedUserIds.contains(p.id) && !existingIds.contains(p.id),
          )
          .toList();
      if (myVersion == _filterVersion) {
        state = state.copyWith(
          profiles: [...state.profiles, ...newProfiles],
          nextCursor: page.nextCursor,
          setNextCursorNull: page.nextCursor == null,
          hasMore: page.hasMore,
          isLoadingMore: false,
        );
      }
    } catch (e, st) {
      log(
        '[SwipeDeck] ERROR loading more profiles: $e',
        error: e,
        stackTrace: st,
      );
      if (myVersion == _filterVersion) {
        state = state.copyWith(isLoadingMore: false, error: e);
      }
    } finally {
      _loadInFlight = false;
    }
    if (myVersion != _filterVersion) {
      await _load();
    }
  }

  /// Advances by moving a cursor over the immutable profile list. The profile
  /// remains available for widget-key reconciliation and for visual undo.
  void advanceAfterSwipe(SwipeProfile profile) {
    final didAdd = _swipedUserIds.add(profile.id);
    // Any already-swiped profile is a replayed/duplicate gesture — ignore it
    // entirely so the deck cursor isn't advanced twice. Undo paths remove the
    // id first, so a legitimate re-swipe after undo still reports didAdd=true.
    if (!didAdd) return;
    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      lastSwipedProfile: profile,
      hasSwiped: true,
      clearError: true,
    );
  }

  /// Reverses an optimistic advance after a failed persisted swipe.
  void rollbackSwipe(SwipeProfile profile) {
    if (state.lastSwipedProfile?.id != profile.id) return;
    final didRemove = _swipedUserIds.remove(profile.id);
    if (!didRemove) return;
    final nextIndex = state.currentIndex > 0 ? state.currentIndex - 1 : 0;
    state = state.copyWith(
      currentIndex: nextIndex,
      hasSwiped: _swipedUserIds.isNotEmpty,
      clearLastSwipedProfile: true,
    );
  }

  bool undoLastSwipe() {
    final last = state.lastSwipedProfile;
    if (last == null || state.currentIndex <= 0) return false;
    _swipedUserIds.remove(last.id);
    state = state.copyWith(
      currentIndex: state.currentIndex - 1,
      hasSwiped: _swipedUserIds.isNotEmpty,
      clearLastSwipedProfile: true,
    );
    return true;
  }

  Future<SwipeResult> persistSwipe({
    required SwipeProfile profile,
    required String action,
  }) async {
    final result = await ref
        .read(swipeRepositoryProvider)
        .swipeProfile(targetUserId: profile.id, action: action);
    _syncSwipeSideEffects(profile: profile, action: action, result: result);
    return result;
  }

  void _syncSwipeSideEffects({
    required SwipeProfile profile,
    required String action,
    required SwipeResult result,
  }) {
    ref
        .read(incomingLikesListControllerProvider.notifier)
        .removePeerOptimistically(profile.id);
    ref.invalidate(incomingLikesProvider);
    unawaited(ref.read(incomingLikesListControllerProvider.notifier).refresh());

    if (action != 'like') return;

    ref
        .read(outgoingLikesListControllerProvider.notifier)
        .upsertOutgoingLike(_outgoingLikeFor(profile));
    ref.invalidate(outgoingLikesProvider);
    unawaited(ref.read(outgoingLikesListControllerProvider.notifier).refresh());

    if (!result.didMatch) return;

    ref.invalidate(conversationsProvider);
    unawaited(ref.read(conversationsListControllerProvider.notifier).refresh());
  }

  IncomingLikeModel _outgoingLikeFor(SwipeProfile profile) {
    return IncomingLikeModel(
      id: -profile.id,
      peer: ChatPeer(
        id: profile.id,
        fullName: profile.fullName ?? 'Flatmate',
        profileImageUrl: profile.profileImageUrl,
        mode: profile.mode,
        city: profile.city,
        locality: profile.locality,
        age: profile.age,
        profession: profile.profession,
      ),
      createdAt: DateTime.now().toUtc(),
    );
  }

  Future<void> recordProfileView({
    required int targetUserId,
    required int durationSeconds,
    int? scrollDepthPercent,
  }) {
    return ref
        .read(swipeRepositoryProvider)
        .recordProfileView(
          targetUserId: targetUserId,
          durationSeconds: durationSeconds,
          scrollDepthPercent: scrollDepthPercent,
        );
  }

  Future<void> refresh() async {
    _swipedUserIds.clear();
    selection.clear();
    await _load();
  }

  /// Multi-select state for the "remove selected" action. Tracks the
  /// property ids the user has ticked in the deck (typically the
  /// shortlist panel — surface via a CTA bar that only shows when the
  /// set is non-empty).
  final Set<int> selection = <int>{};

  bool get hasSelection => selection.isNotEmpty;

  void toggleSelection(int userId) {
    if (selection.contains(userId)) {
      selection.remove(userId);
    } else {
      selection.add(userId);
    }
    // Re-render anything watching hasSelection. We can't easily emit a
    // separate AsyncValue without splitting the controller into two
    // notifiers, so the UI wires selection state through a StateProvider
    // in the page. (Keeping the Set here as a cache keeps the
    // batchRemoveSelected() handler self-contained.)
  }

  /// Calls `POST /swipes/batch-remove` for the currently selected ids and
  /// drops them from the rendered deck on success. No-op when no selection.
  Future<void> batchRemoveSelected() async {
    if (selection.isEmpty) return;
    final ids = selection.toList(growable: false);
    await ref.read(swipeRepositoryProvider).batchRemoveSwipes(ids);
    // The selected users are no longer "liked" — drop them locally so the
    // UI reflects the change immediately. The next page load will reconcile.
    for (final id in ids) {
      _swipedUserIds.add(id);
    }
    state = state.copyWith(
      profiles: state.profiles.where((p) => !selection.contains(p.id)).toList(),
    );
    selection.clear();
  }
}

final swipeDeckControllerProvider =
    NotifierProvider<SwipeDeckController, SwipeDeckState>(
      SwipeDeckController.new,
    );
