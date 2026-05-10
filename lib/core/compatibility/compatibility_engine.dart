import 'package:flutter/material.dart';

import '../theme/app_semantic_colors.dart';

Color compatibilityScoreColor(double percentage) {
  if (percentage >= 70) return AppSemanticColors.compatHigh;
  if (percentage >= 40) return AppSemanticColors.compatMedium;
  return AppSemanticColors.compatLow;
}

class CompatibilityDimension {
  const CompatibilityDimension({
    required this.key,
    required this.weight,
    required this.userValue,
    required this.peerValue,
    required this.score,
    required this.isMatch,
    required this.summary,
  });

  final String key;
  final double weight;
  final String userValue;
  final String peerValue;
  final double score;
  final bool isMatch;
  final String summary;
}

class CompatibilityResult {
  const CompatibilityResult({
    required this.percentage,
    required this.dimensions,
    required this.topMatchChips,
  });

  final double percentage;
  final List<CompatibilityDimension> dimensions;
  final List<String> topMatchChips;
}

class CompatibilityEngine {
  const CompatibilityEngine._();

  static CompatibilityResult calculate({
    required Map<String, String> user,
    required Map<String, String> peer,
  }) {
    final dimensions = <CompatibilityDimension>[];

    dimensions.add(
      _sleepSchedule(
        _normalize('sleep_schedule', user['sleep_schedule'] ?? 'flexible'),
        _normalize('sleep_schedule', peer['sleep_schedule'] ?? 'flexible'),
      ),
    );
    dimensions.add(
      _cleanliness(
        _normalize('cleanliness', user['cleanliness'] ?? 'tidy'),
        _normalize('cleanliness', peer['cleanliness'] ?? 'tidy'),
      ),
    );
    dimensions.add(
      _foodHabits(
        _normalize('food_habits', user['food_habits'] ?? 'no_preference'),
        _normalize('food_habits', peer['food_habits'] ?? 'no_preference'),
      ),
    );
    dimensions.add(
      _smokingDrinking(
        _normalize('smoking_drinking', user['smoking_drinking'] ?? 'neither'),
        _normalize('smoking_drinking', peer['smoking_drinking'] ?? 'neither'),
      ),
    );
    dimensions.add(
      _guestsPolicy(
        _normalize('guests_policy', user['guests_policy'] ?? 'occasional_ok'),
        _normalize('guests_policy', peer['guests_policy'] ?? 'occasional_ok'),
      ),
    );
    dimensions.add(
      _workStyle(
        user['work_style'] ?? 'hybrid',
        peer['work_style'] ?? 'hybrid',
      ),
    );

    double weightedSum = 0;
    double weightTotal = 0;
    for (final dim in dimensions) {
      weightedSum += dim.score * dim.weight;
      weightTotal += dim.weight;
    }

    final percentage = weightTotal > 0
        ? (weightedSum / weightTotal) * 100.0
        : 0.0;

    // Sort dimensions by score (highest first) and take top 3 matches
    final sortedDimensions = List<CompatibilityDimension>.from(dimensions)
      ..sort((a, b) => b.score.compareTo(a.score));

    final topChips = <String>[];
    for (final dim in sortedDimensions) {
      if (dim.isMatch && topChips.length < 3) {
        topChips.add(dim.summary);
      }
    }

    return CompatibilityResult(
      percentage: percentage.clamp(0, 100),
      dimensions: dimensions,
      topMatchChips: topChips,
    );
  }

  static String _normalize(String key, String value) {
    return switch ((key, value)) {
      ('sleep_schedule', 'before_7') => 'early_bird',
      ('sleep_schedule', '7_to_9') => 'flexible',
      ('sleep_schedule', 'after_9') => 'night_owl',
      ('cleanliness', 'laid_back') => 'minimal',
      ('cleanliness', 'balanced') => 'tidy',
      ('cleanliness', 'meticulous') => 'spotless',
      ('food_habits', 'veg') => 'vegetarian',
      ('food_habits', 'non_veg') => 'non_vegetarian',
      ('smoking_drinking', 'never') => 'neither',
      ('smoking_drinking', 'occasionally') => 'drink_occasionally',
      ('smoking_drinking', 'regularly') => 'both_fine',
      ('guests_policy', 'rarely') => 'no_overnight_guests',
      ('guests_policy', 'occasionally') => 'occasional_ok',
      ('guests_policy', 'comfortable') => 'open_house',
      _ => value,
    };
  }

  static CompatibilityDimension _sleepSchedule(String a, String b) {
    const values = ['early_bird', 'flexible', 'night_owl'];
    final ai = values.indexOf(a);
    final bi = values.indexOf(b);
    double score;
    if (ai == bi) {
      score = 100;
    } else if ((ai - bi).abs() == 1) {
      score = 50;
    } else {
      score = 0;
    }
    return CompatibilityDimension(
      key: 'sleep_schedule',
      weight: 0.20,
      userValue: a,
      peerValue: b,
      score: score,
      isMatch: score >= 50,
      summary: score == 100 ? 'Same sleep schedule' : 'Similar sleep habits',
    );
  }

  static CompatibilityDimension _cleanliness(String a, String b) {
    const values = ['minimal', 'tidy', 'spotless'];
    final ai = values.indexOf(a);
    final bi = values.indexOf(b);
    final gap = (ai - bi).abs();
    final score = switch (gap) {
      0 => 100.0,
      1 => 50.0,
      _ => 0.0,
    };
    return CompatibilityDimension(
      key: 'cleanliness',
      weight: 0.20,
      userValue: a,
      peerValue: b,
      score: score,
      isMatch: gap <= 1,
      summary: score == 100 ? 'Same cleanliness level' : 'Similar cleanliness',
    );
  }

  static CompatibilityDimension _foodHabits(String a, String b) {
    // Handle no_preference cases
    if (a == 'no_preference' || b == 'no_preference') {
      return CompatibilityDimension(
        key: 'food_habits',
        weight: 0.15,
        userValue: a,
        peerValue: b,
        score: 100,
        isMatch: true,
        summary: 'Flexible food preferences',
      );
    }

    const strict = {'vegetarian', 'vegan'};
    double score;
    if (a == b) {
      score = 100;
    } else if (strict.contains(a) && strict.contains(b)) {
      // Both vegetarian/vegan - compatible
      score = 100;
    } else if (strict.contains(a) || strict.contains(b)) {
      // One is strict, other is not
      score = 0;
    } else {
      // Both non-vegetarian or flexible
      score = 100;
    }
    return CompatibilityDimension(
      key: 'food_habits',
      weight: 0.15,
      userValue: a,
      peerValue: b,
      score: score,
      isMatch: score >= 50,
      summary: score == 100 ? 'Same food habits' : 'Different food preferences',
    );
  }

  static CompatibilityDimension _smokingDrinking(String a, String b) {
    // Handle no_preference cases
    if (a == 'no_preference' || b == 'no_preference') {
      return CompatibilityDimension(
        key: 'smoking_drinking',
        weight: 0.20,
        userValue: a,
        peerValue: b,
        score: 100,
        isMatch: true,
        summary: 'Flexible lifestyle habits',
      );
    }

    const nonSmoker = {'neither', 'drink_occasionally'};
    const smoker = {'smoke_outside'};
    const drinker = {'drink_occasionally', 'both_fine'};

    double score;
    if (a == b) {
      score = 100;
    } else if (nonSmoker.contains(a) && nonSmoker.contains(b)) {
      // Both non-smokers (one or both may drink)
      score = 80;
    } else if (smoker.contains(a) && smoker.contains(b)) {
      // Both smoke - compatible
      score = 100;
    } else if ((smoker.contains(a) && !smoker.contains(b)) ||
        (!smoker.contains(a) && smoker.contains(b))) {
      // One smokes, other doesn't
      score = 30;
    } else if (drinker.contains(a) && drinker.contains(b)) {
      // Both okay with drinking
      score = 80;
    } else {
      // Mixed preferences
      score = 50;
    }
    return CompatibilityDimension(
      key: 'smoking_drinking',
      weight: 0.20,
      userValue: a,
      peerValue: b,
      score: score,
      isMatch: score >= 50,
      summary: score >= 80
          ? 'Very compatible habits'
          : score >= 50
          ? 'Compatible habits'
          : 'Lifestyle differences',
    );
  }

  static CompatibilityDimension _guestsPolicy(String a, String b) {
    const values = ['no_overnight_guests', 'occasional_ok', 'open_house'];
    final ai = values.indexOf(a);
    final bi = values.indexOf(b);
    final gap = (ai - bi).abs();
    final score = switch (gap) {
      0 => 100.0,
      1 => 60.0,
      _ => 20.0,
    };
    return CompatibilityDimension(
      key: 'guests_policy',
      weight: 0.15,
      userValue: a,
      peerValue: b,
      score: score,
      isMatch: gap <= 1,
      summary: score == 100 ? 'Same guest policy' : 'Similar guest policy',
    );
  }

  static CompatibilityDimension _workStyle(String a, String b) {
    double score;
    if (a == b) {
      score = 100;
    } else if ((a == 'wfh' && b == 'office') || (a == 'office' && b == 'wfh')) {
      score = 40;
    } else {
      score = 70;
    }
    return CompatibilityDimension(
      key: 'work_style',
      weight: 0.10,
      userValue: a,
      peerValue: b,
      score: score,
      isMatch: score >= 50,
      summary: score == 100 ? 'Same work style' : 'Different work styles',
    );
  }
}
