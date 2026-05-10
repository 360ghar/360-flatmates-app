import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SwipeQuotaState {
  const SwipeQuotaState({
    required this.swipesToday,
    required this.superLikesRemaining,
  });

  final int swipesToday;
  final int superLikesRemaining;

  static const int swipesPerDayCap = 100;
  static const int defaultSuperLikes = 3;

  int get swipesRemaining => swipesPerDayCap - swipesToday;
  bool get isCapped => swipesToday >= swipesPerDayCap;

  SwipeQuotaState copyWith({int? swipesToday, int? superLikesRemaining}) {
    return SwipeQuotaState(
      swipesToday: swipesToday ?? this.swipesToday,
      superLikesRemaining: superLikesRemaining ?? this.superLikesRemaining,
    );
  }
}

class SwipeQuotaController extends Notifier<SwipeQuotaState> {
  static const _prefKeySwipesDate = 'swipe_cap_date';
  static const _prefKeySwipesCount = 'swipe_cap_count';
  static const _prefKeySuperLikes = 'swipe_super_likes_remaining';

  @override
  SwipeQuotaState build() {
    _loadSwipeCaps();
    return const SwipeQuotaState(
      swipesToday: 0,
      superLikesRemaining: SwipeQuotaState.defaultSuperLikes,
    );
  }

  Future<void> _loadSwipeCaps() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString(_prefKeySwipesDate);
    int swipesToday = 0;
    bool isNewDay = savedDate != today;
    if (!isNewDay) {
      swipesToday = prefs.getInt(_prefKeySwipesCount) ?? 0;
    } else {
      await prefs.setString(_prefKeySwipesDate, today);
      await prefs.setInt(_prefKeySwipesCount, 0);
    }
    final superLikesRemaining = isNewDay
        ? SwipeQuotaState.defaultSuperLikes
        : (prefs.getInt(_prefKeySuperLikes) ??
              SwipeQuotaState.defaultSuperLikes);
    if (isNewDay) {
      await prefs.setInt(_prefKeySuperLikes, SwipeQuotaState.defaultSuperLikes);
    }
    state = SwipeQuotaState(
      swipesToday: swipesToday,
      superLikesRemaining: superLikesRemaining,
    );
  }

  Future<void> recordSwipe({required bool isSuperLike}) async {
    final prefs = await SharedPreferences.getInstance();
    final newSwipesToday = state.swipesToday + 1;
    final newSuperLikes = isSuperLike
        ? (state.superLikesRemaining - 1).clamp(0, double.infinity).toInt()
        : state.superLikesRemaining;
    await prefs.setInt(_prefKeySwipesCount, newSwipesToday);
    await prefs.setInt(_prefKeySuperLikes, newSuperLikes);
    state = state.copyWith(
      swipesToday: newSwipesToday,
      superLikesRemaining: newSuperLikes,
    );
  }

  Future<void> resetForNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_prefKeySwipesDate, today);
    await prefs.setInt(_prefKeySwipesCount, 0);
    await prefs.setInt(_prefKeySuperLikes, SwipeQuotaState.defaultSuperLikes);
    state = state.copyWith(
      swipesToday: 0,
      superLikesRemaining: SwipeQuotaState.defaultSuperLikes,
    );
  }
}

final swipeQuotaControllerProvider =
    NotifierProvider<SwipeQuotaController, SwipeQuotaState>(
      SwipeQuotaController.new,
    );
