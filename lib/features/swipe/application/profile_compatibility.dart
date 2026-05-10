import '../../../core/compatibility/compatibility_engine.dart';
import '../../bootstrap/domain/bootstrap_models.dart';
import '../swipe_repository.dart';

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
