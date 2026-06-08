import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../discover/discover_repository.dart';
import '../swipe_repository.dart';

class SwipeDeckController extends Notifier<AsyncValue<List<SwipeProfile>>> {
  final Set<int> _swipedUserIds = {};

  @override
  AsyncValue<List<SwipeProfile>> build() {
    Future.microtask(() => _load());
    return const AsyncLoading();
  }

  Future<void> _load() async {
    state = const AsyncLoading();
    try {
      final filters = ref.read(discoverFiltersProvider);
      if (kDebugMode) {
        log('[SwipeDeck] Loading profiles, filters=$filters');
      } else {
        log('[SwipeDeck] Loading profiles');
      }
      final profiles = await ref
          .read(swipeRepositoryProvider)
          .fetchSwipeProfiles(filters: filters);
      if (kDebugMode) {
        log('[SwipeDeck] Loaded ${profiles.length} profiles');
      } else {
        log('[SwipeDeck] Loaded ${profiles.length} profiles');
      }
      final filtered = profiles
          .where((p) => !_swipedUserIds.contains(p.id))
          .toList();
      state = AsyncData(filtered);
    } catch (e, st) {
      if (kDebugMode) {
        log('[SwipeDeck] ERROR loading profiles: $e', error: e, stackTrace: st);
      } else {
        log('[SwipeDeck] ERROR loading profiles');
      }
      state = AsyncError(e, st);
    }
  }

  void markSwiped(int userId) {
    _swipedUserIds.add(userId);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.where((p) => p.id != userId).toList());
    }
  }

  void undoSwipe(SwipeProfile profile) {
    final wasSwiped = _swipedUserIds.remove(profile.id);
    if (!wasSwiped) return;
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData([profile, ...current]);
    }
  }

  Future<void> refresh() async {
    _swipedUserIds.clear();
    await _load();
  }
}

final swipeDeckControllerProvider =
    NotifierProvider<SwipeDeckController, AsyncValue<List<SwipeProfile>>>(
      SwipeDeckController.new,
    );
