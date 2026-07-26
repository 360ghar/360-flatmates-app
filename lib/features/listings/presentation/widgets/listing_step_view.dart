import 'package:flutter/material.dart';

import '../../../bootstrap/catalog_helpers.dart';
import 'listing_form_data.dart';
import 'listing_step_metadata.dart';
import 'step_about_section.dart';
import 'step_costs_section.dart';
import 'step_flat_section.dart';
import 'step_location_section.dart';
import 'step_review_section.dart';
import 'step_room_section.dart';
import 'step_society_section.dart';

/// Bundles every per-step callback the create-listing builder needs, so the
/// step dispatcher can live outside the (otherwise large) page widget.
class ListingStepCallbacks {
  const ListingStepCallbacks({
    required this.onFieldChanged,
    required this.onSocietyTypeChanged,
    required this.onSocietyAmenityToggled,
    required this.onVibeToggled,
    required this.onRoomTypeChanged,
    required this.onFurnishingToggled,
    required this.onFeatureToggled,
    required this.onPickPhotos,
    required this.onRemovePhoto,
    required this.onVideoTourUrlChanged,
    required this.onVideoUploadingChanged,
    required this.onFlatConfigChanged,
    required this.onFlatAmenityToggled,
    required this.onElectricityChanged,
    required this.onGenderChanged,
    required this.onAgeRangeChanged,
    required this.onNonNegotiableToggled,
    required this.onAvailableFromChanged,
    required this.onGoToStep,
  });

  final VoidCallback onFieldChanged;
  final ValueChanged<String> onSocietyTypeChanged;
  final void Function(String key, bool selected) onSocietyAmenityToggled;
  final void Function(String key, bool selected) onVibeToggled;
  final ValueChanged<String> onRoomTypeChanged;
  final void Function(String key, bool selected) onFurnishingToggled;
  final void Function(String key, bool selected) onFeatureToggled;
  final VoidCallback onPickPhotos;
  final void Function(int index) onRemovePhoto;
  final void Function(String? url) onVideoTourUrlChanged;
  final void Function(bool uploading) onVideoUploadingChanged;
  final ValueChanged<String> onFlatConfigChanged;
  final void Function(String key, bool selected) onFlatAmenityToggled;
  final ValueChanged<String> onElectricityChanged;
  final ValueChanged<String> onGenderChanged;
  final void Function(double min, double max) onAgeRangeChanged;
  final void Function(String key, bool selected) onNonNegotiableToggled;
  final void Function(DateTime? date) onAvailableFromChanged;
  final void Function(int step) onGoToStep;
}

/// Renders the current step of the create/edit listing flow.
class ListingStepView extends StatelessWidget {
  const ListingStepView({
    required this.step,
    required this.data,
    required this.catalog,
    required this.catalogLabel,
    required this.showSocietyValidation,
    required this.showCityValidation,
    required this.showLocalityValidation,
    required this.showRentValidation,
    required this.showDepositValidation,
    required this.showMaintenanceValidation,
    required this.showCostValidation,
    required this.showElectricityValidation,
    required this.showPhotosValidation,
    required this.callbacks,
    super.key,
  });

  final int step;
  final ListingFormData data;
  final List<CatalogOption> Function(String key) catalog;
  final String Function(String key, String id) catalogLabel;
  final bool showSocietyValidation;
  final bool showCityValidation;
  final bool showLocalityValidation;
  final bool showRentValidation;
  final bool showDepositValidation;
  final bool showMaintenanceValidation;
  final bool showCostValidation;
  final bool showElectricityValidation;
  final bool showPhotosValidation;
  final ListingStepCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    return switch (step) {
      0 => StepLocationSection(
        societyController: data.societyController,
        addressController: data.addressController,
        cityController: data.cityController,
        localityController: data.localityController,
        showSocietyValidation: showSocietyValidation,
        showCityValidation: showCityValidation,
        showLocalityValidation: showLocalityValidation,
        onChanged: callbacks.onFieldChanged,
      ),
      1 => StepSocietySection(
        societyType: data.societyType,
        societyAmenities: data.societyAmenities,
        societyVibeTags: data.societyVibeTags,
        catalog: catalog,
        iconForOption: listingIconForOption,
        onSocietyTypeChanged: callbacks.onSocietyTypeChanged,
        onAmenityToggled: callbacks.onSocietyAmenityToggled,
        onVibeToggled: callbacks.onVibeToggled,
      ),
      2 || 3 => StepRoomSection(
        step: step,
        roomType: data.roomType,
        roomFurnishing: data.roomFurnishing,
        roomFeatures: data.roomFeatures,
        roomPhotoUrls: data.roomPhotoUrls,
        videoTourUrl: data.videoTourUrl,
        videoUploading: data.videoUploading,
        showPhotosValidation: showPhotosValidation,
        catalog: catalog,
        iconForOption: listingIconForOption,
        onRoomTypeChanged: callbacks.onRoomTypeChanged,
        onFurnishingToggled: callbacks.onFurnishingToggled,
        onFeatureToggled: callbacks.onFeatureToggled,
        onPickPhotos: callbacks.onPickPhotos,
        onRemovePhoto: callbacks.onRemovePhoto,
        onVideoTourUrlChanged: callbacks.onVideoTourUrlChanged,
        onVideoUploadingChanged: callbacks.onVideoUploadingChanged,
      ),
      4 => StepFlatSection(
        flatConfig: data.flatConfig,
        floorController: data.floorController,
        totalFloorsController: data.totalFloorsController,
        flatAmenities: data.flatAmenities,
        catalog: catalog,
        iconForOption: listingIconForOption,
        onFlatConfigChanged: callbacks.onFlatConfigChanged,
        onAmenityToggled: callbacks.onFlatAmenityToggled,
      ),
      5 => StepCostsSection(
        rentController: data.rentController,
        depositController: data.depositController,
        maintenanceController: data.maintenanceController,
        electricityIncluded: data.electricityIncluded,
        electricityEstController: data.electricityEstController,
        cookCostController: data.cookCostController,
        maidCostController: data.maidCostController,
        setupCostController: data.setupCostController,
        showRentValidation: showRentValidation,
        showDepositValidation: showDepositValidation,
        showMaintenanceValidation: showMaintenanceValidation,
        showCostValidation: showCostValidation,
        showElectricityValidation: showElectricityValidation,
        totalMonthlyOutflow: data.totalMonthlyOutflow,
        flatConfig: data.flatConfig,
        onElectricityChanged: callbacks.onElectricityChanged,
        onChanged: callbacks.onFieldChanged,
      ),
      6 => StepAboutSection(
        typicalDayController: data.typicalDayController,
        genderPreference: data.genderPreference,
        ageMin: data.ageMin,
        ageMax: data.ageMax,
        nonNegotiables: data.nonNegotiables,
        availableFrom: data.availableFrom,
        catalog: catalog,
        onGenderChanged: callbacks.onGenderChanged,
        onAgeRangeChanged: callbacks.onAgeRangeChanged,
        onNonNegotiableToggled: callbacks.onNonNegotiableToggled,
        onAvailableFromChanged: callbacks.onAvailableFromChanged,
      ),
      7 => StepReviewSection(
        data: data,
        catalogLabel: catalogLabel,
        totalMonthlyOutflow: data.totalMonthlyOutflow,
        onGoToStep: callbacks.onGoToStep,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
