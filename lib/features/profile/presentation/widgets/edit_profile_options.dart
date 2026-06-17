import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../bootstrap/bootstrap_controller.dart';
import '../../../bootstrap/catalog_helpers.dart';
import 'edit_profile_sections.dart';

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
    return _resolve('flatmates_modes', [
      DropdownMenuItem(
        value: 'room_poster',
        child: Text(locale.modeRoomPoster),
      ),
      DropdownMenuItem(value: 'seeker', child: Text(locale.modeSeeker)),
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

  List<DropdownMenuItem<String>> timelineItems() {
    return _resolve('flatmates_move_in_timelines', [
      DropdownMenuItem(value: 'immediate', child: Text(locale.moveInImmediate)),
      DropdownMenuItem(
        value: 'this_month',
        child: Text(locale.moveInThisMonth),
      ),
      DropdownMenuItem(
        value: 'next_month',
        child: Text(locale.moveInNextMonth),
      ),
      DropdownMenuItem(value: 'flexible', child: Text(locale.moveInAnytime)),
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

  List<NonNegotiableOption> nonNegotiableOptions() {
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
}
