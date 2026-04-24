import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/core/compatibility/compatibility_engine.dart';

void main() {
  group('CompatibilityEngine', () {
    test('exact match on all dimensions yields 100%', () {
      final user = <String, String>{
        'sleep_schedule': 'early_bird',
        'cleanliness': 'tidy',
        'food_habits': 'vegetarian',
        'smoking_drinking': 'neither',
        'guests_policy': 'occasional_ok',
        'work_style': 'hybrid',
      };

      final result = CompatibilityEngine.calculate(user: user, peer: user);

      expect(result.percentage, 100.0);
      expect(result.dimensions.every((d) => d.score == 100), isTrue);
      // All dimensions are matches, so we should get up to 3 top match chips.
      expect(result.topMatchChips.length, 3);
    });

    test('opposite sleep schedule yields lower sleep score', () {
      final earlyBird = {'sleep_schedule': 'early_bird'};
      final nightOwl = {'sleep_schedule': 'night_owl'};

      final result = CompatibilityEngine.calculate(
        user: earlyBird,
        peer: nightOwl,
      );

      // early_bird and night_owl differ by 2 positions (gap = 2), score = 0.
      final sleepDim = result.dimensions.firstWhere(
        (d) => d.key == 'sleep_schedule',
      );
      expect(sleepDim.score, 0.0);
      expect(sleepDim.isMatch, isFalse);
    });

    test('strict veg + non-veg yields low food score', () {
      final user = <String, String>{'food_habits': 'vegetarian'};
      final peer = <String, String>{'food_habits': 'non_vegetarian'};

      final result = CompatibilityEngine.calculate(user: user, peer: peer);

      final foodDim = result.dimensions.firstWhere(
        (d) => d.key == 'food_habits',
      );
      // vegetarian (strict) + non_vegetarian (non-strict) => score = 0.
      expect(foodDim.score, 0.0);
      expect(foodDim.isMatch, isFalse);
    });

    test('vegan + non-veg also yields low food score', () {
      final user = <String, String>{'food_habits': 'vegan'};
      final peer = <String, String>{'food_habits': 'non_vegetarian'};

      final result = CompatibilityEngine.calculate(user: user, peer: peer);

      final foodDim = result.dimensions.firstWhere(
        (d) => d.key == 'food_habits',
      );
      expect(foodDim.score, 0.0);
    });

    test('two non-strict diets get full food score', () {
      final user = <String, String>{'food_habits': 'non_vegetarian'};
      final peer = <String, String>{'food_habits': 'no_preference'};

      final result = CompatibilityEngine.calculate(user: user, peer: peer);

      final foodDim = result.dimensions.firstWhere(
        (d) => d.key == 'food_habits',
      );
      // Both are non-strict => score = 100.
      expect(foodDim.score, 100.0);
    });

    test('same food habits yields 100 food score', () {
      final user = <String, String>{'food_habits': 'vegetarian'};
      final peer = <String, String>{'food_habits': 'vegetarian'};

      final result = CompatibilityEngine.calculate(user: user, peer: peer);

      final foodDim = result.dimensions.firstWhere(
        (d) => d.key == 'food_habits',
      );
      expect(foodDim.score, 100.0);
    });

    test('weights are correctly applied', () {
      // All dimensions identical => 100% regardless of weights.
      final profile = <String, String>{
        'sleep_schedule': 'flexible',
        'cleanliness': 'tidy',
        'food_habits': 'no_preference',
        'smoking_drinking': 'neither',
        'guests_policy': 'occasional_ok',
        'work_style': 'hybrid',
      };

      final result = CompatibilityEngine.calculate(user: profile, peer: profile);
      expect(result.percentage, 100.0);

      // Verify weight sum.
      final weightSum = result.dimensions.fold<double>(
        0.0,
        (sum, d) => sum + d.weight,
      );
      // 0.20 + 0.20 + 0.15 + 0.20 + 0.15 + 0.10 = 1.0
      expect(weightSum, closeTo(1.0, 0.001));
    });

    test('defaults to flexible/tidy when keys are missing', () {
      final result = CompatibilityEngine.calculate(
        user: <String, String>{},
        peer: <String, String>{},
      );

      // Both default to same values, so all scores should be 100.
      expect(result.percentage, 100.0);
    });

    test('wfh + office yields lower work style score', () {
      final user = <String, String>{'work_style': 'wfh'};
      final peer = <String, String>{'work_style': 'office'};

      final result = CompatibilityEngine.calculate(user: user, peer: peer);

      final workDim = result.dimensions.firstWhere(
        (d) => d.key == 'work_style',
      );
      expect(workDim.score, 40.0);
    });

    test('topMatchChips limits to at most 3', () {
      final profile = <String, String>{
        'sleep_schedule': 'flexible',
        'cleanliness': 'tidy',
        'food_habits': 'no_preference',
        'smoking_drinking': 'neither',
        'guests_policy': 'occasional_ok',
        'work_style': 'hybrid',
      };

      final result = CompatibilityEngine.calculate(user: profile, peer: profile);
      // All 6 dimensions match, but chips are capped at 3.
      expect(result.topMatchChips.length, 3);
    });
  });
}
