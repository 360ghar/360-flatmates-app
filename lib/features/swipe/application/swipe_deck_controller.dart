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
      final profiles = await ref
          .read(swipeRepositoryProvider)
          .fetchSwipeProfiles(filters: filters);
      final filtered = profiles
          .where((p) => !_swipedUserIds.contains(p.id))
          .toList();
      state = AsyncData(filtered);
    } catch (e, st) {
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

  Future<void> refresh() async {
    _swipedUserIds.clear();
    await _load();
  }
}

final swipeDeckControllerProvider =
    NotifierProvider<SwipeDeckController, AsyncValue<List<SwipeProfile>>>(
  SwipeDeckController.new,
);
