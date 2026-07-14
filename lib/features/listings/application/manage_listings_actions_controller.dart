import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../listings_repository.dart';
import '../my_listings_controller.dart';

/// Pause/resume mutation UI state for manage listings.
class ManageListingsActionsState {
  const ManageListingsActionsState({
    this.pausingIds = const <int>{},
    this.optimisticPaused = const <int, bool>{},
  });

  /// Listing ids currently mid-flight on a pause/resume request.
  final Set<int> pausingIds;

  /// Optimistic paused flag by listing id (true = paused, false = live).
  /// Cleared after success (list refresh) or failure (rollback).
  final Map<int, bool> optimisticPaused;

  bool isPausing(int listingId) => pausingIds.contains(listingId);

  /// Effective paused state: prefer optimistic override when present.
  bool isPaused(int listingId, {required bool fromListing}) {
    return optimisticPaused[listingId] ?? fromListing;
  }

  ManageListingsActionsState copyWith({
    Set<int>? pausingIds,
    Map<int, bool>? optimisticPaused,
  }) {
    return ManageListingsActionsState(
      pausingIds: pausingIds ?? this.pausingIds,
      optimisticPaused: optimisticPaused ?? this.optimisticPaused,
    );
  }
}

/// Application-layer controller for manage-listings mutations (pause/resume).
///
/// Owns optimistic pause/resume with rollback and keeps repository calls out of
/// the widget layer (see CLAUDE.md "Business logic in controllers").
class ManageListingsActionsController
    extends Notifier<ManageListingsActionsState> {
  @override
  ManageListingsActionsState build() => const ManageListingsActionsState();

  /// Toggles pause for [listingId]. [currentlyPaused] is the UI's current
  /// paused state (true → resume, false → pause).
  ///
  /// Applies an optimistic paused override immediately and rolls it back on
  /// failure. On success, invalidates the listings list so the server state
  /// becomes authoritative.
  Future<void> togglePause(
    int listingId, {
    required bool currentlyPaused,
  }) async {
    if (state.pausingIds.contains(listingId)) return;

    final nextPaused = !currentlyPaused;
    state = state.copyWith(
      pausingIds: {...state.pausingIds, listingId},
      optimisticPaused: {...state.optimisticPaused, listingId: nextPaused},
    );

    try {
      await ref
          .read(listingsRepositoryProvider)
          .togglePause(listingId, paused: currentlyPaused);
      ref.invalidate(myListingsListControllerProvider);
      ref.invalidate(myListingsProvider);
      // Drop the optimistic override after a successful mutate so the refreshed
      // list is the source of truth.
      final clearedOptimistic = Map<int, bool>.of(state.optimisticPaused)
        ..remove(listingId);
      state = state.copyWith(optimisticPaused: clearedOptimistic);
    } catch (e) {
      debugPrint('ManageListingsActionsController.togglePause: $e');
      final rolledBack = Map<int, bool>.of(state.optimisticPaused)
        ..remove(listingId);
      state = state.copyWith(optimisticPaused: rolledBack);
      rethrow;
    } finally {
      state = state.copyWith(
        pausingIds: {...state.pausingIds}..remove(listingId),
      );
    }
  }
}

final manageListingsActionsControllerProvider =
    NotifierProvider<
      ManageListingsActionsController,
      ManageListingsActionsState
    >(ManageListingsActionsController.new);
