import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../listings_repository.dart';

/// Immutable snapshot of all listing form data, passed to step widgets.
class ListingFormData {
  const ListingFormData({
    // Location
    required this.societyController,
    required this.addressController,
    required this.cityController,
    required this.localityController,
    // Society
    required this.societyType,
    required this.societyAmenities,
    required this.societyVibeTags,
    // Room
    required this.roomType,
    required this.roomFurnishing,
    required this.roomFeatures,
    required this.roomPhotoUrls,
    required this.videoTourUrl,
    required this.videoUploading,
    // Flat
    required this.flatConfig,
    required this.floorController,
    required this.totalFloorsController,
    required this.flatAmenities,
    // Costs
    required this.rentController,
    required this.depositController,
    required this.maintenanceController,
    required this.electricityIncluded,
    required this.electricityEstController,
    required this.cookCostController,
    required this.maidCostController,
    required this.setupCostController,
    // About
    required this.typicalDayController,
    required this.genderPreference,
    required this.ageMin,
    required this.ageMax,
    required this.nonNegotiables,
    required this.availableFrom,
  });

  // Location
  final TextEditingController societyController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController localityController;
  // Society
  final String societyType;
  final Set<String> societyAmenities;
  final Set<String> societyVibeTags;
  // Room
  final String roomType;
  final Set<String> roomFurnishing;
  final Set<String> roomFeatures;
  final List<String> roomPhotoUrls;
  final String? videoTourUrl;
  final bool videoUploading;
  // Flat
  final String flatConfig;
  final TextEditingController floorController;
  final TextEditingController totalFloorsController;
  final Set<String> flatAmenities;
  // Costs
  final TextEditingController rentController;
  final TextEditingController depositController;
  final TextEditingController maintenanceController;
  final String electricityIncluded;
  final TextEditingController electricityEstController;
  final TextEditingController cookCostController;
  final TextEditingController maidCostController;
  final TextEditingController setupCostController;
  // About
  final TextEditingController typicalDayController;
  final String genderPreference;
  final double ageMin;
  final double ageMax;
  final Set<String> nonNegotiables;
  final DateTime? availableFrom;

  /// Convenience getters for trimmed text values.
  String get society => societyController.text.trim();
  String get address => addressController.text.trim();
  String get city => cityController.text.trim();
  String get locality => localityController.text.trim();
  String get rent => rentController.text.trim();
  String get deposit => depositController.text.trim();
  String get maintenance => maintenanceController.text.trim();
  String get typicalDay => typicalDayController.text.trim();
  String get floor => floorController.text.trim();
  String get totalFloors => totalFloorsController.text.trim();

  int get bedrooms => flatConfig.contains('1')
      ? 1
      : flatConfig.contains('3')
      ? 3
      : flatConfig.contains('4')
      ? 4
      : 2;

  /// Build the [ListingCreateRequest] from current form state.
  ListingCreateRequest toRequest() {
    final features = [
      ...roomFurnishing,
      ...roomFeatures,
      ...flatAmenities,
      ...societyAmenities,
    ];
    if (videoTourUrl != null && !features.contains('video_tour')) {
      features.add('video_tour');
    }

    return ListingCreateRequest(
      title: '$flatConfig in $society',
      description: typicalDay.isEmpty ? null : typicalDay,
      city: city.isEmpty ? null : city,
      locality: locality.isEmpty ? null : locality,
      subLocality: society.isEmpty ? null : society,
      monthlyRent: double.parse(rent),
      securityDeposit: double.tryParse(deposit),
      maintenanceCharges: double.tryParse(maintenance),
      areaSqft: null,
      bedrooms: bedrooms,
      bathrooms: 1,
      features: features,
      tags: societyVibeTags.toList(growable: false),
      mainImageUrl: roomPhotoUrls.isNotEmpty ? roomPhotoUrls.first : null,
      imageUrls: roomPhotoUrls,
      availableFrom: availableFrom,
      genderPreference: genderPreference,
      sharingType: roomType,
      societyType: societyType,
      societyAmenities: societyAmenities.toList(growable: false),
      societyVibeTags: societyVibeTags.toList(growable: false),
      videoTourUrl: videoTourUrl,
    );
  }

  /// Returns a brief summary of data for the step just completed.
  String? stepSummary(
    AppLocalizations locale,
    int step,
    String Function(String key, String id) catalogLabel,
  ) {
    if (step == 0) return null;
    return switch (step) {
      1 =>
        society.isNotEmpty
            ? locale.listingSummaryLocation(society, city)
            : null,
      2 => locale.listingSummarySociety(
        catalogLabel('flatmates_society_types', societyType),
      ),
      3 => locale.listingSummaryRoom(
        catalogLabel('flatmates_room_types', roomType),
        roomFurnishing.length,
      ),
      4 => locale.listingSummaryPhotos(
        roomPhotoUrls.length,
        roomPhotoUrls.length != 1 ? 's' : '',
      ),
      5 => locale.listingSummaryFlat(flatConfig, floor.isEmpty ? '-' : floor),
      6 => rent.isNotEmpty ? locale.listingSummaryCosts(rent) : null,
      7 => locale.listingSummaryAbout(
        genderPreference == 'any'
            ? locale.genderAny
            : genderPreference == 'male'
            ? locale.genderMale
            : locale.genderFemale,
        ageMin.round().toString(),
        ageMax.round().toString(),
      ),
      _ => null,
    };
  }
}
