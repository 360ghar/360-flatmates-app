import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import 'flatmates_ui.dart';

/// Localized labels, icons and grouping for the seven lifestyle dimensions.
///
/// Shared by every surface that renders someone's lifestyle — the chat peer
/// profile page and the discover owner profile sheet — which previously each
/// carried their own near-identical copy of these lookups. Pure data and pure
/// functions: no `BuildContext`, no `WidgetRef`, no widget state.
///
/// Sits beside [profile_sections.dart], which owns the `LifestyleCell` /
/// `LifestyleGrid` / `PreferencesCard` widgets these labels feed. Imported
/// directly — it is deliberately not exported from `components.dart`, matching
/// the precedent set by `profile_sections.dart`.

/// Dimension keys grouped into the sections shown on a profile.
const lifestyleGroups = <String, List<String>>{
  'Routine': ['sleep_schedule', 'cleanliness'],
  'Diet': ['food_habits'],
  'Habits': ['smoking', 'drinking', 'guests_policy'],
  'Work': ['work_style'],
};

/// Icon shown next to each lifestyle dimension.
const lifestyleFieldIcons = <String, IconData>{
  'sleep_schedule': Icons.bedtime_outlined,
  'cleanliness': Icons.cleaning_services_outlined,
  'food_habits': Icons.restaurant_outlined,
  'smoking': Icons.smoking_rooms_outlined,
  'drinking': Icons.local_bar_outlined,
  'guests_policy': Icons.groups_outlined,
  'work_style': Icons.work_outline_rounded,
};

/// Localized name of a lifestyle dimension (the row's title).
String lifestyleDimLabel(AppLocalizations locale, String key) {
  switch (key) {
    case 'sleep_schedule':
      return locale.lifestyleDimSleep;
    case 'cleanliness':
      return locale.lifestyleDimCleanliness;
    case 'food_habits':
      return locale.lifestyleDimFood;
    case 'smoking':
      return locale.smokingLabel;
    case 'drinking':
      return locale.drinkingLabel;
    case 'guests_policy':
      return locale.lifestyleDimGuests;
    case 'work_style':
      return locale.lifestyleDimWork;
    default:
      return humanizeFlatmatesToken(key);
  }
}

/// Maps a lifestyle field key + raw backend value to a localized display label
/// using the existing quiz ARB keys.
///
/// Unrecognized values fall back to [humanizeFlatmatesToken] so a new server
/// enum still renders readably instead of leaking a raw token.
String lifestyleValueLabel(AppLocalizations l, String key, String raw) =>
    switch (key) {
      'sleep_schedule' => switch (raw) {
        'early_bird' => l.quizEarlyBird,
        'flexible' => l.quizFlexible,
        'night_owl' => l.quizNightOwl,
        _ => humanizeFlatmatesToken(raw),
      },
      'cleanliness' => switch (raw) {
        'minimal' => l.quizCleanMinimal,
        'tidy' => l.quizCleanTidy,
        'spotless' => l.quizCleanSpotless,
        _ => humanizeFlatmatesToken(raw),
      },
      'food_habits' => switch (raw) {
        'vegetarian' => l.quizVegetarian,
        'vegan' => l.quizVegan,
        'non_vegetarian' => l.quizNonVegetarian,
        'eggetarian' => l.quizEggetarian,
        'no_preference' => l.quizNoFoodPref,
        _ => humanizeFlatmatesToken(raw),
      },
      'smoking' => switch (raw) {
        'never' => l.lifestyleValueNever,
        'occasionally' => l.lifestyleValueOccasionally,
        'regularly' => l.lifestyleValueRegularly,
        _ => humanizeFlatmatesToken(raw),
      },
      'drinking' => switch (raw) {
        'never' => l.lifestyleValueNever,
        'occasionally' => l.lifestyleValueOccasionally,
        'regularly' => l.lifestyleValueRegularly,
        _ => humanizeFlatmatesToken(raw),
      },
      'guests_policy' => switch (raw) {
        'no_overnight_guests' => l.quizNoGuests,
        'occasional_ok' => l.quizOccasionalGuests,
        'open_house' => l.quizOpenHouse,
        _ => humanizeFlatmatesToken(raw),
      },
      'work_style' => switch (raw) {
        'wfh' => l.quizWfh,
        'office' => l.quizOffice,
        'hybrid' => l.quizHybrid,
        _ => humanizeFlatmatesToken(raw),
      },
      _ => humanizeFlatmatesToken(raw),
    };
