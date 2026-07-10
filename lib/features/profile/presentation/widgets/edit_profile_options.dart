import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../bootstrap/bootstrap_controller.dart';
import '../../../bootstrap/catalog_helpers.dart';
import '../../../bootstrap/domain/bootstrap_models.dart';
import 'edit_profile_dropdown_utils.dart';
import 'edit_profile_sections.dart';

/// Dropdown field values resolved against current catalog/fallback item ids.
class EditProfileSeedValues {
  const EditProfileSeedValues({
    this.mode,
    this.workStyle,
    this.moveInTimeline,
    this.sleepSchedule,
    this.cleanliness,
    this.foodHabits,
    this.smokingDrinking,
    this.guestsPolicy,
    this.nonNegotiables = const [],
    this.photoUrls = const [],
  });

  final String? mode;
  final String? workStyle;
  final String? moveInTimeline;
  final String? sleepSchedule;
  final String? cleanliness;
  final String? foodHabits;
  final String? smokingDrinking;
  final String? guestsPolicy;
  final List<String> nonNegotiables;
  final List<String> photoUrls;
}

/// Builds dropdown items and option lists for the edit-profile form, preferring
/// server-driven catalog options (via [BootstrapData.catalogOptions]) and
/// falling back to localized defaults.
///
/// Extracted from the page to keep `edit_profile_page.dart` under the 500-line
/// limit and to centralize the catalog/fallback resolution logic.
class EditProfileOptions {
  const EditProfileOptions({required this.locale, required this.bootstrap});

  final AppLocalizations locale;
  final BootstrapData? bootstrap;

  /// Safe selected value for a generic dropdown (exact id match only).
  String? safeValue(String? value, List<DropdownMenuItem<String>> items) {
    return dropdownValueInIds(value, items.map((item) => item.value));
  }

  /// Safe selected value for move-in timeline (applies legacy id aliases).
  String? safeMoveInValue(String? value, List<DropdownMenuItem<String>> items) {
    final ids = items.map((item) => item.value);
    final resolved = resolveMoveInTimelineId(value, ids);
    return dropdownValueInIds(resolved, ids);
  }

  /// Maps profile fields onto ids present in the current dropdown item lists.
  EditProfileSeedValues seedFromProfile(FlatmatesProfileModel profile) {
    String? exact(String? value, List<DropdownMenuItem<String>> items) =>
        dropdownValueInIds(value, items.map((item) => item.value));

    final prefs = profile.preferences;
    final nonNeg = prefs['non_negotiables'] is List
        ? List<String>.from(prefs['non_negotiables'] as List)
        : const <String>[];

    return EditProfileSeedValues(
      mode: exact(profile.mode, modeItems()),
      workStyle: exact(profile.workStyle, workStyleItems()),
      moveInTimeline: resolveMoveInTimelineId(
        profile.moveInTimeline,
        timelineItems().map((item) => item.value),
      ),
      sleepSchedule: exact(profile.sleepSchedule, sleepItems()),
      cleanliness: exact(profile.cleanliness, cleanlinessItems()),
      foodHabits: exact(profile.foodHabits, foodItems()),
      smokingDrinking: exact(profile.smokingDrinking, smokingItems()),
      guestsPolicy: exact(profile.guestsPolicy, guestsItems()),
      nonNegotiables: nonNeg,
      photoUrls: profile.profileImageUrl != null
          ? [profile.profileImageUrl!]
          : const [],
    );
  }

  List<DropdownMenuItem<String>> _resolve(
    String catalogKey,
    List<DropdownMenuItem<String>> fallback,
  ) {
    final catalogOpts = bootstrap?.catalogOptions(catalogKey);
    if (catalogOpts != null && catalogOpts.isNotEmpty) {
      return catalogOpts
          .map((opt) => DropdownMenuItem(value: opt.id, child: Text(opt.label)))
          .toList();
    }
    return fallback;
  }

  List<DropdownMenuItem<String>> modeItems() {
    // Match backend catalog `flatmates_modes` (no legacy `seeker`).
    return _resolve('flatmates_modes', [
      DropdownMenuItem(
        value: 'room_poster',
        child: Text(locale.modeRoomPoster),
      ),
      DropdownMenuItem(value: 'co_hunter', child: Text(locale.modeCoHunter)),
      DropdownMenuItem(
        value: 'open_to_both',
        child: Text(locale.modeOpenToBoth),
      ),
    ]);
  }

  List<DropdownMenuItem<String>> workStyleItems() {
    return _resolve('flatmates_work_styles', [
      DropdownMenuItem(value: 'office', child: Text(locale.workStyleOffice)),
      DropdownMenuItem(value: 'hybrid', child: Text(locale.workStyleHybrid)),
      DropdownMenuItem(value: 'wfh', child: Text(locale.workStyleWfh)),
    ]);
  }

  /// Prefer catalog when bootstrap is loaded. Fallback ids match the server
  /// catalog (`flatmates_move_in_timelines`); [resolveMoveInTimelineId] maps
  /// legacy values (`flexible`, `immediate`, …) onto these.
  List<DropdownMenuItem<String>> timelineItems() {
    return _resolve('flatmates_move_in_timelines', [
      DropdownMenuItem(
        value: 'immediately',
        child: Text(locale.moveInImmediate),
      ),
      DropdownMenuItem(
        value: 'within_2_weeks',
        child: Text(locale.moveInWithin2Weeks),
      ),
      DropdownMenuItem(
        value: 'within_1_month',
        child: Text(locale.moveInThisMonth),
      ),
      DropdownMenuItem(
        value: 'just_exploring',
        child: Text(locale.moveInJustExploring),
      ),
    ]);
  }

  List<DropdownMenuItem<String>> sleepItems() {
    return _resolve('flatmates_lifestyle_sleep', [
      DropdownMenuItem(value: 'early_bird', child: Text(locale.quizEarlyBird)),
      DropdownMenuItem(value: 'flexible', child: Text(locale.quizFlexible)),
      DropdownMenuItem(value: 'night_owl', child: Text(locale.quizNightOwl)),
    ]);
  }

  List<DropdownMenuItem<String>> cleanlinessItems() {
    return _resolve('flatmates_lifestyle_cleanliness', [
      DropdownMenuItem(value: 'minimal', child: Text(locale.quizCleanMinimal)),
      DropdownMenuItem(value: 'tidy', child: Text(locale.quizCleanTidy)),
      DropdownMenuItem(
        value: 'spotless',
        child: Text(locale.quizCleanSpotless),
      ),
    ]);
  }

  List<DropdownMenuItem<String>> foodItems() {
    return _resolve('flatmates_lifestyle_food', [
      DropdownMenuItem(value: 'vegetarian', child: Text(locale.quizVegetarian)),
      DropdownMenuItem(value: 'vegan', child: Text(locale.quizVegan)),
      DropdownMenuItem(
        value: 'non_vegetarian',
        child: Text(locale.quizNonVegetarian),
      ),
      DropdownMenuItem(
        value: 'no_preference',
        child: Text(locale.quizNoFoodPref),
      ),
    ]);
  }

  List<DropdownMenuItem<String>> smokingItems() {
    return _resolve('flatmates_lifestyle_smoking', [
      DropdownMenuItem(value: 'neither', child: Text(locale.quizNeither)),
      DropdownMenuItem(
        value: 'smoke_outside',
        child: Text(locale.quizSmokeOutside),
      ),
      DropdownMenuItem(
        value: 'drink_occasionally',
        child: Text(locale.quizDrinkOccasionally),
      ),
      DropdownMenuItem(value: 'both_fine', child: Text(locale.quizBothFine)),
    ]);
  }

  List<DropdownMenuItem<String>> guestsItems() {
    return _resolve('flatmates_lifestyle_guests', [
      DropdownMenuItem(
        value: 'no_overnight_guests',
        child: Text(locale.quizNoGuests),
      ),
      DropdownMenuItem(
        value: 'occasional_ok',
        child: Text(locale.quizOccasionalGuests),
      ),
      DropdownMenuItem(value: 'open_house', child: Text(locale.quizOpenHouse)),
    ]);
  }

  static const _nonNegotiablesCatalogKey = 'flatmates_non_negotiables';

  List<NonNegotiableOption> nonNegotiableOptions() {
    final catalogOpts = bootstrap?.catalogOptions(_nonNegotiablesCatalogKey);
    if (catalogOpts != null && catalogOpts.isNotEmpty) {
      return catalogOpts
          .map(
            (opt) => NonNegotiableOption(
              opt.id,
              opt.label,
              _iconForNonNegotiable(opt.id),
            ),
          )
          .toList();
    }
    return _fallbackNonNegotiableOptions();
  }

  List<NonNegotiableOption> _fallbackNonNegotiableOptions() {
    return [
      NonNegotiableOption(
        'food_veg_only',
        locale.nonNegVegOnly,
        Icons.restaurant,
      ),
      NonNegotiableOption('food_vegan_only', locale.nonNegVeganOnly, Icons.eco),
      NonNegotiableOption(
        'no_smoking',
        locale.nonNegNoSmoking,
        Icons.smoke_free,
      ),
      NonNegotiableOption(
        'no_drinking',
        locale.nonNegNoDrinking,
        Icons.no_drinks,
      ),
      NonNegotiableOption(
        'no_overnight_guests',
        locale.nonNegNoGuests,
        Icons.nightlight,
      ),
      NonNegotiableOption('no_pets', locale.nonNegNoPets, Icons.pets),
      NonNegotiableOption(
        'gender_female_only',
        locale.nonNegFemaleOnly,
        Icons.female,
      ),
      NonNegotiableOption(
        'gender_male_only',
        locale.nonNegMaleOnly,
        Icons.male,
      ),
      NonNegotiableOption(
        'no_parties',
        locale.nonNegNoParties,
        Icons.do_not_disturb,
      ),
      NonNegotiableOption(
        'min_tidy',
        locale.nonNegMinTidy,
        Icons.cleaning_services,
      ),
    ];
  }

  IconData _iconForNonNegotiable(String id) {
    return switch (id) {
      'food_veg_only' => Icons.restaurant,
      'food_vegan_only' => Icons.eco,
      'no_smoking' => Icons.smoke_free,
      'no_drinking' => Icons.no_drinks,
      'no_overnight_guests' => Icons.nightlight,
      'no_pets' => Icons.pets,
      'gender_female_only' => Icons.female,
      'gender_male_only' => Icons.male,
      'no_parties' => Icons.do_not_disturb,
      'min_tidy' => Icons.cleaning_services,
      _ => Icons.block,
    };
  }
}
