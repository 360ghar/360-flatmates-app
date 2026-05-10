import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';

String listingStepTitle(AppLocalizations locale, int step) {
  return switch (step) {
    0 => locale.listingStepLocation,
    1 => locale.listingStepSociety,
    2 => locale.listingStepRoom,
    3 => locale.addPhotosTitle,
    4 => locale.listingStepFlat,
    5 => locale.listingStepCosts,
    6 => locale.listingStepAbout,
    7 => locale.reviewTitle,
    _ => '',
  };
}

String listingStepHelperText(AppLocalizations locale, int step) {
  return switch (step) {
    0 => locale.listingHelperLocation,
    1 => locale.listingHelperSociety,
    2 => locale.listingHelperRoom,
    3 => locale.listingHelperPhotos,
    4 => locale.listingHelperFlat,
    5 => locale.listingHelperCosts,
    6 => locale.listingHelperAbout,
    7 => locale.listingHelperReview,
    _ => '',
  };
}

IconData listingIconForOption(String id) {
  return switch (id) {
    'wifi' => Icons.wifi_outlined,
    'parking' => Icons.local_parking_outlined,
    'security' => Icons.security_outlined,
    'lift' => Icons.elevator_outlined,
    'washing_machine' => Icons.local_laundry_service_outlined,
    'attached_bathroom' => Icons.bathtub_outlined,
    'balcony' || 'private_balcony' => Icons.balcony_outlined,
    'ac' => Icons.ac_unit_outlined,
    'pet_friendly' => Icons.pets_outlined,
    _ => Icons.check_circle_outline,
  };
}
