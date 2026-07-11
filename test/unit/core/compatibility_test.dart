import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/core/compatibility/compatibility_engine.dart';

void main() {
  group('CompatibilityEngine', () {
    test('exact match on all dimensions yields 100%', () {
      final user = <String, String>{
        'sleep_schedule': 'flexible',
        'cleanliness': 'tidy',
        'food_habits': 'vegetarian',
        'smoking_drinking': 'neither',
        'guests_policy': 'occasional_ok',
        'work_style': 'hybrid',
      };
      final result = CompatibilityEngine.calculate(user: user, peer: user);
      expect(result.percentage, 100.0);
      expect(result.dimensions, hasLength(6));
      for (final dim in result.dimensions) {
        expect(dim.score, 100.0);
        expect(dim.isMatch, isTrue);
      }
    });

    test('opposite sleep schedule yields lower sleep score', () {
      final result = CompatibilityEngine.calculate(
        user: {'sleep_schedule': 'early_bird'},
        peer: {'sleep_schedule': 'night_owl'},
      );
      final sleepDim = result.dimensions.firstWhere(
        (d) => d.key == 'sleep_schedule',
      );
      expect(sleepDim.score, 0.0);
      expect(sleepDim.isMatch, isFalse);
    });

    test('strict veg + non-veg yields low food score', () {
      final result = CompatibilityEngine.calculate(
        user: {'food_habits': 'veg'},
        peer: {'food_habits': 'non_veg'},
      );
      final foodDim = result.dimensions.firstWhere(
        (d) => d.key == 'food_habits',
      );
      expect(foodDim.score, 0.0);
      expect(foodDim.isMatch, isFalse);
    });

    test('vegan + non-veg also yields low food score', () {
      final result = CompatibilityEngine.calculate(
        user: {'food_habits': 'vegan'},
        peer: {'food_habits': 'non_veg'},
      );
      final foodDim = result.dimensions.firstWhere(
        (d) => d.key == 'food_habits',
      );
      expect(foodDim.score, 0.0);
    });

    test('two non-strict diets get full food score', () {
      final result = CompatibilityEngine.calculate(
        user: {'food_habits': 'non_veg'},
        peer: {'food_habits': 'eggetarian'},
      );
      final foodDim = result.dimensions.firstWhere(
        (d) => d.key == 'food_habits',
      );
      expect(foodDim.score, 100.0);
    });

    test('same food habits yields 100 food score', () {
      final result = CompatibilityEngine.calculate(
        user: {'food_habits': 'vegetarian'},
        peer: {'food_habits': 'vegetarian'},
      );
      final foodDim = result.dimensions.firstWhere(
        (d) => d.key == 'food_habits',
      );
      expect(foodDim.score, 100.0);
    });

    test('vegetarian and vegan are compatible (both strict)', () {
      final result = CompatibilityEngine.calculate(
        user: {'food_habits': 'vegetarian'},
        peer: {'food_habits': 'vegan'},
      );
      final foodDim = result.dimensions.firstWhere(
        (d) => d.key == 'food_habits',
      );
      expect(foodDim.score, 100.0);
    });

    test('no_preference food yields 100 food score with anything', () {
      final result = CompatibilityEngine.calculate(
        user: {'food_habits': 'no_preference'},
        peer: {'food_habits': 'non_veg'},
      );
      final foodDim = result.dimensions.firstWhere(
        (d) => d.key == 'food_habits',
      );
      expect(foodDim.score, 100.0);
    });

    test('weights are correctly applied', () {
      // All dimensions match → 100%
      final fullMatch = CompatibilityEngine.calculate(
        user: {
          'sleep_schedule': 'flexible',
          'cleanliness': 'tidy',
          'food_habits': 'vegetarian',
          'smoking_drinking': 'neither',
          'guests_policy': 'occasional_ok',
          'work_style': 'hybrid',
        },
        peer: {
          'sleep_schedule': 'flexible',
          'cleanliness': 'tidy',
          'food_habits': 'vegetarian',
          'smoking_drinking': 'neither',
          'guests_policy': 'occasional_ok',
          'work_style': 'hybrid',
        },
      );
      expect(fullMatch.percentage, 100.0);

      // Verify weight totals: 0.20 + 0.20 + 0.15 + 0.20 + 0.15 + 0.10 = 1.0
      final totalWeight = fullMatch.dimensions.fold<double>(
        0.0,
        (sum, dim) => sum + dim.weight,
      );
      expect(totalWeight, closeTo(1.0, 0.001));
    });

    test('defaults to flexible/tidy when keys are missing', () {
      final result = CompatibilityEngine.calculate(
        user: <String, String>{},
        peer: <String, String>{},
      );
      // With defaults (flexible, tidy, no_preference, neither,
      // occasional_ok, hybrid), both user and peer match → 100%.
      expect(result.percentage, 100.0);
    });

    test('wfh + office yields lower work style score', () {
      final result = CompatibilityEngine.calculate(
        user: {'work_style': 'wfh'},
        peer: {'work_style': 'office'},
      );
      final workDim = result.dimensions.firstWhere(
        (d) => d.key == 'work_style',
      );
      expect(workDim.score, 40.0);
      expect(workDim.isMatch, isFalse);
    });

    test('topMatchChips limits to at most 3', () {
      final result = CompatibilityEngine.calculate(
        user: {
          'sleep_schedule': 'flexible',
          'cleanliness': 'tidy',
          'food_habits': 'vegetarian',
          'smoking_drinking': 'neither',
          'guests_policy': 'occasional_ok',
          'work_style': 'hybrid',
        },
        peer: {
          'sleep_schedule': 'flexible',
          'cleanliness': 'tidy',
          'food_habits': 'vegetarian',
          'smoking_drinking': 'neither',
          'guests_policy': 'occasional_ok',
          'work_style': 'hybrid',
        },
      );
      expect(result.topMatchChips.length, lessThanOrEqualTo(3));
    });

    test('topMatchChips contains only matching dimensions', () {
      final result = CompatibilityEngine.calculate(
        user: {'sleep_schedule': 'early_bird'},
        peer: {'sleep_schedule': 'night_owl'},
      );
      // Sleep doesn't match, so it should not be in chips.
      expect(result.topMatchChips, isNot(contains('Sleep habits')));
    });

    test('cleanliness one-step gap yields 50 score', () {
      final result = CompatibilityEngine.calculate(
        user: {'cleanliness': 'tidy'},
        peer: {'cleanliness': 'minimal'},
      );
      final dim = result.dimensions.firstWhere((d) => d.key == 'cleanliness');
      expect(dim.score, 50.0);
      expect(dim.isMatch, isTrue);
    });

    test('guests policy one-step gap yields 60 score', () {
      final result = CompatibilityEngine.calculate(
        user: {'guests_policy': 'occasional_ok'},
        peer: {'guests_policy': 'no_overnight_guests'},
      );
      final dim = result.dimensions.firstWhere((d) => d.key == 'guests_policy');
      expect(dim.score, 60.0);
    });

    test('percentage is clamped between 0 and 100', () {
      final result = CompatibilityEngine.calculate(
        user: {'sleep_schedule': 'early_bird'},
        peer: {'sleep_schedule': 'night_owl'},
      );
      expect(result.percentage, greaterThanOrEqualTo(0));
      expect(result.percentage, lessThanOrEqualTo(100));
    });
  });
}
