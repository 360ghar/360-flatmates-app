import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../theme/app_semantic_colors.dart';

/// Stable localization keys stored in [CompatibilityDimension.summary].
///
/// The engine has no [BuildContext], so it records a key rather than display
/// text. Render sites resolve the key via [compatSummaryLabel], which has a
/// locale. Server-provided compatibility (chats) carries free-text summaries
/// instead; those are not keys and fall through untranslated.
abstract final class CompatSummaryKey {
  static const sleepHabits = 'compat.sleepHabits';
  static const cleanliness = 'compat.cleanliness';
  static const flexibleFood = 'compat.flexibleFood';
  static const foodMatch = 'compat.foodMatch';
  static const foodDiffer = 'compat.foodDiffer';
  static const flexibleLifestyle = 'compat.flexibleLifestyle';
  static const lifestyleAligned = 'compat.lifestyleAligned';
  static const lifestyleMixed = 'compat.lifestyleMixed';
  static const lifestyleDiffer = 'compat.lifestyleDiffer';
  static const guestPolicy = 'compat.guestPolicy';
  static const workStyle = 'compat.workStyle';
  static const workDiffer = 'compat.workDiffer';
}

/// Resolves a [CompatibilityDimension.summary] to a localized label.
///
/// Engine-produced summaries are [CompatSummaryKey] values and get translated.
/// Anything unrecognized (e.g. a server free-text summary) passes through
/// unchanged so backend-driven breakdowns still render their own text.
String compatSummaryLabel(AppLocalizations locale, String summary) {
  switch (summary) {
    case CompatSummaryKey.sleepHabits:
      return locale.compatSleepHabits;
    case CompatSummaryKey.cleanliness:
      return locale.compatCleanliness;
    case CompatSummaryKey.flexibleFood:
      return locale.compatFlexibleFood;
    case CompatSummaryKey.foodMatch:
      return locale.compatFoodMatch;
    case CompatSummaryKey.foodDiffer:
      return locale.compatFoodDiffer;
    case CompatSummaryKey.flexibleLifestyle:
      return locale.compatFlexibleLifestyle;
    case CompatSummaryKey.lifestyleAligned:
      return locale.compatLifestyleAligned;
    case CompatSummaryKey.lifestyleMixed:
      return locale.compatLifestyleMixed;
    case CompatSummaryKey.lifestyleDiffer:
      return locale.compatLifestyleDiffer;
    case CompatSummaryKey.guestPolicy:
      return locale.compatGuestPolicy;
    case CompatSummaryKey.workStyle:
      return locale.compatWorkStyle;
    case CompatSummaryKey.workDiffer:
      return locale.compatWorkDiffer;
    default:
      return summary;
  }
}

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

    String getVal(Map<String, String> map, String key, String defaultVal) {
      final val = map[key];
      if (val == null) return defaultVal;
      if (key == 'food_habits') {
        if (val == 'veg') return 'vegetarian';
        if (val == 'non_veg') return 'non_vegetarian';
      }
      if (key == 'smoking' || key == 'drinking') {
        if (val == 'no') return 'never';
        if (val == 'yes') return 'regularly';
      }
      return val;
    }

    dimensions.add(
      _sleepSchedule(
        getVal(user, 'sleep_schedule', 'flexible'),
        getVal(peer, 'sleep_schedule', 'flexible'),
      ),
    );
    dimensions.add(
      _cleanliness(
        getVal(user, 'cleanliness', 'tidy'),
        getVal(peer, 'cleanliness', 'tidy'),
      ),
    );
    dimensions.add(
      _foodHabits(
        getVal(user, 'food_habits', 'no_preference'),
        getVal(peer, 'food_habits', 'no_preference'),
      ),
    );
    dimensions.add(
      _smoking(
        getVal(user, 'smoking', 'never'),
        getVal(peer, 'smoking', 'never'),
      ),
    );
    dimensions.add(
      _drinking(
        getVal(user, 'drinking', 'never'),
        getVal(peer, 'drinking', 'never'),
      ),
    );
    dimensions.add(
      _guestsPolicy(
        getVal(user, 'guests_policy', 'occasional_ok'),
        getVal(peer, 'guests_policy', 'occasional_ok'),
      ),
    );
    dimensions.add(
      _workStyle(
        getVal(user, 'work_style', 'hybrid'),
        getVal(peer, 'work_style', 'hybrid'),
      ),
    );

    double weightedSum = 0;
    double weightTotal = 0;
    for (final dim in dimensions) {
      weightedSum += dim.score * dim.weight;
      weightTotal += dim.weight;
    }

    final percentage = weightTotal > 0 ? (weightedSum / weightTotal) : 0.0;

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

  static CompatibilityDimension _sleepSchedule(String a, String b) {
    const values = ['early_bird', 'flexible', 'night_owl'];
    final ai = values.indexOf(a);
    final bi = values.indexOf(b);
    if (ai < 0 || bi < 0) {
      _warnUnknownEnum('sleep_schedule', a, b, values);
      return CompatibilityDimension(
        key: 'sleep_schedule',
        weight: 0.20,
        userValue: a,
        peerValue: b,
        score: 0,
        isMatch: false,
        summary: CompatSummaryKey.sleepHabits,
      );
    }
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
      summary: CompatSummaryKey.sleepHabits,
    );
  }

  static CompatibilityDimension _cleanliness(String a, String b) {
    const values = ['minimal', 'tidy', 'spotless'];
    final ai = values.indexOf(a);
    final bi = values.indexOf(b);
    if (ai < 0 || bi < 0) {
      _warnUnknownEnum('cleanliness', a, b, values);
      return CompatibilityDimension(
        key: 'cleanliness',
        weight: 0.20,
        userValue: a,
        peerValue: b,
        score: 0,
        isMatch: false,
        summary: CompatSummaryKey.cleanliness,
      );
    }
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
      summary: CompatSummaryKey.cleanliness,
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
        summary: CompatSummaryKey.flexibleFood,
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
      summary: score == 100
          ? CompatSummaryKey.foodMatch
          : CompatSummaryKey.foodDiffer,
    );
  }

  /// Shared scoring for the smoking / drinking lifestyle dimensions.
  ///
  /// Values are ordered never < occasionally < regularly. Same value scores
  /// 100, adjacent values 70, and the extreme pair (never vs regularly) 40,
  /// mirroring the backend's split scoring. Either side reporting
  /// `no_preference` (legacy value) is treated as fully flexible.
  static CompatibilityDimension _smoking(String a, String b) =>
      _lifestyleHabit('smoking', 0.10, a, b);

  static CompatibilityDimension _drinking(String a, String b) =>
      _lifestyleHabit('drinking', 0.10, a, b);

  static CompatibilityDimension _lifestyleHabit(
    String key,
    double weight,
    String a,
    String b,
  ) {
    if (a == 'no_preference' || b == 'no_preference') {
      return CompatibilityDimension(
        key: key,
        weight: weight,
        userValue: a,
        peerValue: b,
        score: 100,
        isMatch: true,
        summary: CompatSummaryKey.flexibleLifestyle,
      );
    }

    const values = ['never', 'occasionally', 'regularly'];
    final ai = values.indexOf(a);
    final bi = values.indexOf(b);
    if (ai < 0 || bi < 0) {
      _warnUnknownEnum(key, a, b, values);
      return CompatibilityDimension(
        key: key,
        weight: weight,
        userValue: a,
        peerValue: b,
        score: 0,
        isMatch: false,
        summary: CompatSummaryKey.lifestyleDiffer,
      );
    }
    final gap = (ai - bi).abs();
    final score = switch (gap) {
      0 => 100.0,
      1 => 70.0,
      _ => 40.0,
    };
    return CompatibilityDimension(
      key: key,
      weight: weight,
      userValue: a,
      peerValue: b,
      score: score,
      isMatch: score >= 70,
      summary: score >= 80
          ? CompatSummaryKey.lifestyleAligned
          : score >= 50
          ? CompatSummaryKey.lifestyleMixed
          : CompatSummaryKey.lifestyleDiffer,
    );
  }

  static CompatibilityDimension _guestsPolicy(String a, String b) {
    const values = ['no_overnight_guests', 'occasional_ok', 'open_house'];
    final ai = values.indexOf(a);
    final bi = values.indexOf(b);
    if (ai < 0 || bi < 0) {
      _warnUnknownEnum('guests_policy', a, b, values);
      return CompatibilityDimension(
        key: 'guests_policy',
        weight: 0.15,
        userValue: a,
        peerValue: b,
        score: 0,
        isMatch: false,
        summary: CompatSummaryKey.guestPolicy,
      );
    }
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
      summary: CompatSummaryKey.guestPolicy,
    );
  }

  static void _warnUnknownEnum(
    String key,
    String a,
    String b,
    List<String> known,
  ) {
    if (kReleaseMode) return;
    debugPrint(
      '[CompatibilityEngine] Unknown $key value(s): a="$a" b="$b". '
      'Expected one of $known. Scoring as 0.',
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
      summary: score == 100
          ? CompatSummaryKey.workStyle
          : CompatSummaryKey.workDiffer,
    );
  }
}
