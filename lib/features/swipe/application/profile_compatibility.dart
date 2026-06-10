import '../../../core/compatibility/compatibility_engine.dart';
import '../../bootstrap/domain/bootstrap_models.dart';
import '../swipe_repository.dart';

/// Memoizes [calculateProfileCompatibility] per peer profile id. Swipe drag
/// gestures rebuild every frame, so scoring must not rerun per rebuild.
class ProfileCompatibilityCache {
  final _results = <int, CompatibilityResult>{};
  FlatmatesProfileModel? _user;

  CompatibilityResult resultFor(
    FlatmatesProfileModel? user,
    SwipeProfile peer,
  ) {
    if (!identical(user, _user)) {
      _results.clear();
      _user = user;
    }
    return _results.putIfAbsent(
      peer.id,
      () => calculateProfileCompatibility(user, peer),
    );
  }

  void clear() => _results.clear();
}

CompatibilityResult calculateProfileCompatibility(
  FlatmatesProfileModel? user,
  SwipeProfile peer,
) {
  return CompatibilityEngine.calculate(
    user: {
      'sleep_schedule': user?.sleepSchedule ?? 'flexible',
      'cleanliness': user?.cleanliness ?? 'tidy',
      'food_habits': user?.foodHabits ?? 'no_preference',
      'smoking_drinking': user?.smokingDrinking ?? 'neither',
      'guests_policy': user?.guestsPolicy ?? 'occasional_ok',
      'work_style': user?.workStyle ?? 'hybrid',
    },
    peer: {
      'sleep_schedule': peer.sleepSchedule ?? 'flexible',
      'cleanliness': peer.cleanliness ?? 'tidy',
      'food_habits': peer.foodHabits ?? 'no_preference',
      'smoking_drinking': peer.smokingDrinking ?? 'neither',
      'guests_policy': peer.guestsPolicy ?? 'occasional_ok',
      'work_style': peer.workStyle ?? 'hybrid',
    },
  );
}
