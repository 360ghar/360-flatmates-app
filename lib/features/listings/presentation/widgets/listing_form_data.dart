import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../discover/domain/property_listing.dart';
import '../../listings_repository.dart';

/// Inline validation flags surfaced on the current step.
typedef ListingStepValidation = ({
  bool rent,
  bool deposit,
  bool maintenance,
  bool cost,
  bool electricity,
  bool photos,
});

const ListingStepValidation kNoListingValidation = (
  rent: false,
  deposit: false,
  maintenance: false,
  cost: false,
  electricity: false,
  photos: false,
);

/// Computes which inline validation hints to show for [step]. Optional numeric
/// fields are flagged only when present but unparseable; required fields when
/// missing. Pure so it is unit-testable and keeps the page widget small.
ListingStepValidation computeStepValidation(ListingFormData data, int step) {
  bool invalidNumber(String v) => v.isNotEmpty && double.tryParse(v) == null;
  if (step == 3) {
    return (kNoListingValidation).copyWithPhotos(data.roomPhotoUrls.length < 2);
  }
  if (step != 5) return kNoListingValidation;
  final estText = data.electricityEstController.text.trim();
  return (
    rent: data.rent.isEmpty || double.tryParse(data.rent) == null,
    deposit: invalidNumber(data.deposit),
    maintenance: invalidNumber(data.maintenance),
    cost:
        invalidNumber(data.cookCostController.text.trim()) ||
        invalidNumber(data.maidCostController.text.trim()),
    electricity:
        data.electricityIncluded == 'separate' &&
        (estText.isEmpty || double.tryParse(estText) == null),
    photos: false,
  );
}

extension on ListingStepValidation {
  ListingStepValidation copyWithPhotos(bool value) => (
    rent: rent,
    deposit: deposit,
    maintenance: maintenance,
    cost: cost,
    electricity: electricity,
    photos: value,
  );
}

/// Scalar (non-controller, non-set) listing fields restored when editing.
typedef ListingEditScalars = ({
  String roomType,
  String societyType,
  String genderPreference,
  String flatConfig,
  String? videoTourUrl,
  DateTime? availableFrom,
});

/// Populates [controllers] and the mutable [sets] in place from [listing] for
/// edit mode, returning the remaining scalar fields for the caller to apply.
/// Keeps the listing→form mapping in the data layer (off the page widget).
ListingEditScalars populateListingControllers({
  required PropertyListing listing,
  required TextEditingController society,
  required TextEditingController address,
  required TextEditingController city,
  required TextEditingController locality,
  required TextEditingController rent,
  required TextEditingController deposit,
  required TextEditingController maintenance,
  required TextEditingController typicalDay,
  required TextEditingController floor,
  required TextEditingController totalFloors,
  required Set<String> roomFeatures,
  required Set<String> societyAmenities,
  required Set<String> societyVibeTags,
  required List<String> roomPhotoUrls,
  required String fallbackRoomType,
  required String fallbackSocietyType,
  required String fallbackGenderPreference,
}) {
  final prefs = listing.preferences ?? const <String, dynamic>{};
  // Society/building name lives in sub_locality, not the composed title.
  society.text = listing.subLocality ?? _stripConfigPrefix(listing.title);
  address.text = prefs['full_address'] as String? ?? '';
  city.text = listing.city ?? '';
  locality.text = listing.locality ?? '';
  rent.text = listing.monthlyRent.toStringAsFixed(0);
  deposit.text = listing.securityDeposit?.toStringAsFixed(0) ?? '';
  maintenance.text = listing.maintenanceCharges?.toStringAsFixed(0) ?? '';
  typicalDay.text = listing.description ?? '';
  if (listing.floorNumber != null) floor.text = '${listing.floorNumber}';
  if (listing.totalFloors != null) {
    totalFloors.text = '${listing.totalFloors}';
  }
  roomFeatures
    ..clear()
    ..addAll(listing.features.where((f) => f != 'video_tour'));
  societyAmenities
    ..clear()
    ..addAll((prefs['society_amenities'] as List?)?.cast<String>() ?? const []);
  societyVibeTags
    ..clear()
    ..addAll((prefs['society_vibes'] as List?)?.cast<String>() ?? listing.tags);
  roomPhotoUrls
    ..clear()
    ..addAll(listing.imageUrls);
  return (
    roomType: listing.sharingType ?? fallbackRoomType,
    societyType: prefs['society_type'] as String? ?? fallbackSocietyType,
    genderPreference: listing.genderPreference ?? fallbackGenderPreference,
    flatConfig: switch (listing.bedrooms) {
      1 => '1BHK',
      3 => '3BHK',
      final int b when b >= 4 => '4BHK',
      _ => '2BHK',
    },
    videoTourUrl: listing.videoTourUrl,
    availableFrom: listing.availableFrom,
  );
}

/// Removes a leading "NBHK in " prefix (e.g. "2BHK in ") so editing a listing
/// whose title was composed by the builder does not double up on re-submit.
String _stripConfigPrefix(String title) {
  final match = RegExp(r'^\d+BHK in ').firstMatch(title);
  return match == null ? title : title.substring(match.end);
}

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

  /// Total monthly outflow (rent + recurring charges) used for the cost summary.
  double get totalMonthlyOutflow {
    final rentValue = double.tryParse(rent) ?? 0;
    final maintenanceValue = double.tryParse(maintenance) ?? 0;
    final electricityValue = electricityIncluded == 'separate'
        ? (double.tryParse(electricityEstController.text.trim()) ?? 0)
        : 0;
    final cook = double.tryParse(cookCostController.text.trim()) ?? 0;
    final maid = double.tryParse(maidCostController.text.trim()) ?? 0;
    return rentValue + maintenanceValue + electricityValue + cook + maid;
  }

  /// Whether the given [step] has the minimum required input to advance.
  bool canProceed(int step) {
    return switch (step) {
      0 => society.isNotEmpty && city.isNotEmpty && locality.isNotEmpty,
      3 => roomPhotoUrls.length >= 2,
      5 =>
        rent.isNotEmpty &&
            double.tryParse(rent) != null &&
            (electricityIncluded != 'separate' ||
                (electricityEstController.text.trim().isNotEmpty &&
                    double.tryParse(electricityEstController.text.trim()) !=
                        null)),
      1 || 2 || 4 || 6 || 7 => true,
      _ => false,
    };
  }

  /// Whether the form has the minimum data required to publish a listing
  /// (location, ≥2 photos, valid rent / electricity when separate).
  bool get canPublish => canProceed(0) && canProceed(3) && canProceed(5);

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
      // Form has no bathrooms control; default matches draft submit path.
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
      fullAddress: address.isEmpty ? null : address,
      floorNumber: int.tryParse(floor),
      totalFloors: int.tryParse(totalFloors),
      ageMin: ageMin.round(),
      ageMax: ageMax.round(),
      nonNegotiables: nonNegotiables.toList(growable: false),
      electricityIncluded: electricityIncluded,
      electricityEst: double.tryParse(electricityEstController.text.trim()),
      cookCost: double.tryParse(cookCostController.text.trim()),
      maidCost: double.tryParse(maidCostController.text.trim()),
      setupCost: double.tryParse(setupCostController.text.trim()),
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
