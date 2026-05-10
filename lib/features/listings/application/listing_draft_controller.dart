import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/app_failure.dart';
import '../../bootstrap/bootstrap_controller.dart';
import '../../discover/discover_repository.dart';
import '../listings_repository.dart';
import '../domain/listing_draft_state.dart';

class ListingDraftController extends Notifier<ListingDraftState> {
  static const String _prefsKey = 'listing_draft';

  @override
  ListingDraftState build() {
    _restoreDraft();
    return const ListingDraftState();
  }

  Future<void> _restoreDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('$_prefsKey:step');
      if (saved == null) return;
      final step = ListingDraftStep.values.firstWhere(
        (s) => s.name == saved,
        orElse: () => ListingDraftStep.location,
      );
      state = state.copyWith(step: step);
    } catch (e) {
      // Log but don't block — draft restore is best-effort
      debugPrint('ListingDraftController._restoreDraft failed: $e');
    }
  }

  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefsKey:step', state.step.name);
    } catch (_) {}
  }

  // ── Step navigation ──────────────────────────────────────────────

  void updateStep(ListingDraftStep step) {
    state = state.copyWith(step: step);
    _saveDraft();
  }

  bool goToNextStep() {
    if (!validateCurrentStep()) return false;
    final nextIndex = state.stepIndex + 1;
    if (nextIndex < ListingDraftStep.values.length) {
      state = state.copyWith(step: ListingDraftStep.values[nextIndex]);
      _saveDraft();
      return true;
    }
    return false;
  }

  void goToPreviousStep() {
    final prevIndex = state.stepIndex - 1;
    if (prevIndex >= 0) {
      state = state.copyWith(step: ListingDraftStep.values[prevIndex]);
      _saveDraft();
    }
  }

  // ── Field updaters ───────────────────────────────────────────────

  void updateLocation({
    String? society,
    String? address,
    String? city,
    String? locality,
  }) {
    state = state.copyWith(
      society: society,
      address: address,
      city: city,
      locality: locality,
    );
  }

  void updateSociety({
    String? societyType,
    Set<String>? amenities,
    Set<String>? vibeTags,
  }) {
    state = state.copyWith(
      societyType: societyType,
      societyAmenities: amenities,
      societyVibeTags: vibeTags,
    );
  }

  void updateRoom({
    String? roomType,
    Set<String>? furnishing,
    Set<String>? features,
    List<String>? photoUrls,
    String? videoTourUrl,
    bool? videoUploading,
  }) {
    state = state.copyWith(
      roomType: roomType,
      roomFurnishing: furnishing,
      roomFeatures: features,
      roomPhotoUrls: photoUrls,
      videoTourUrl: videoTourUrl,
      videoUploading: videoUploading,
    );
  }

  void updateFlat({
    String? flatConfig,
    String? floor,
    String? totalFloors,
    Set<String>? amenities,
  }) {
    state = state.copyWith(
      flatConfig: flatConfig,
      floor: floor,
      totalFloors: totalFloors,
      flatAmenities: amenities,
    );
  }

  void updateCosts({
    String? rent,
    String? deposit,
    String? maintenance,
    String? electricityIncluded,
    String? electricityEst,
    String? cookCost,
    String? maidCost,
    String? setupCost,
  }) {
    state = state.copyWith(
      rent: rent,
      deposit: deposit,
      maintenance: maintenance,
      electricityIncluded: electricityIncluded,
      electricityEst: electricityEst,
      cookCost: cookCost,
      maidCost: maidCost,
      setupCost: setupCost,
    );
  }

  void updateAbout({
    String? typicalDay,
    String? genderPreference,
    double? ageMin,
    double? ageMax,
    Set<String>? nonNegotiables,
    DateTime? availableFrom,
  }) {
    state = state.copyWith(
      typicalDay: typicalDay,
      genderPreference: genderPreference,
      ageMin: ageMin,
      ageMax: ageMax,
      nonNegotiables: nonNegotiables,
      availableFrom: availableFrom,
    );
  }

  // ── Validation ───────────────────────────────────────────────────

  bool validateCurrentStep() {
    final error = switch (state.step) {
      ListingDraftStep.location =>
        (state.society.trim().isEmpty ||
                state.city.trim().isEmpty ||
                state.locality.trim().isEmpty)
            ? 'Location details are required'
            : null,
      ListingDraftStep.room =>
        state.roomPhotoUrls.length < 2
            ? 'At least 2 photos are required'
            : null,
      ListingDraftStep.costs =>
        (state.rent.trim().isEmpty ||
                double.tryParse(state.rent.trim()) == null)
            ? 'Valid rent amount is required'
            : null,
      _ => null,
    };

    if (error != null) {
      state = state.copyWith(validationError: error);
      return false;
    }
    state = state.copyWith(clearValidationError: true);
    return true;
  }

  bool get canProceed {
    return switch (state.step) {
      ListingDraftStep.location =>
        state.society.trim().isNotEmpty &&
            state.city.trim().isNotEmpty &&
            state.locality.trim().isNotEmpty,
      ListingDraftStep.society => true,
      ListingDraftStep.room => state.roomPhotoUrls.length >= 2,
      ListingDraftStep.flat => true,
      ListingDraftStep.costs =>
        state.rent.trim().isNotEmpty &&
            double.tryParse(state.rent.trim()) != null,
      ListingDraftStep.about => true,
      ListingDraftStep.preferences => true,
      ListingDraftStep.review => true,
    };
  }

  double get totalMonthlyOutflow {
    final rent = double.tryParse(state.rent.trim()) ?? 0;
    final maintenance = double.tryParse(state.maintenance.trim()) ?? 0;
    final electricity = state.electricityIncluded == 'separate'
        ? (double.tryParse(state.electricityEst.trim()) ?? 0)
        : 0;
    final cook = double.tryParse(state.cookCost.trim()) ?? 0;
    final maid = double.tryParse(state.maidCost.trim()) ?? 0;
    return rent + maintenance + electricity + cook + maid;
  }

  // ── Submission ───────────────────────────────────────────────────

  /// Submits the listing draft. Returns the listing ID on success, or null on failure.
  Future<int?> submit() async {
    if (state.isSubmitting) return null;
    state = state.copyWith(isSubmitting: true, clearSubmitError: true);

    try {
      // Build features list, adding video_tour tag if video tour exists
      final features = <String>[
        ...state.roomFurnishing,
        ...state.roomFeatures,
        ...state.flatAmenities,
        ...state.societyAmenities,
      ];
      if (state.videoTourUrl != null && !features.contains('video_tour')) {
        features.add('video_tour');
      }

      // Parse bedroom count from flat config string
      final bedrooms = state.flatConfig.contains('1')
          ? 1
          : state.flatConfig.contains('3')
          ? 3
          : state.flatConfig.contains('4')
          ? 4
          : 2;

      final request = ListingCreateRequest(
        title: '${state.flatConfig} in ${state.society.trim()}',
        description: state.typicalDay.trim().isEmpty
            ? null
            : state.typicalDay.trim(),
        city: state.city.trim().isEmpty ? null : state.city.trim(),
        locality: state.locality.trim().isEmpty ? null : state.locality.trim(),
        subLocality: state.society.trim().isEmpty ? null : state.society.trim(),
        monthlyRent: double.parse(state.rent.trim()),
        securityDeposit: double.tryParse(state.deposit.trim()),
        maintenanceCharges: double.tryParse(state.maintenance.trim()),
        areaSqft: null,
        bedrooms: bedrooms,
        bathrooms: 1,
        features: features,
        tags: state.societyVibeTags.toList(growable: false),
        mainImageUrl: state.roomPhotoUrls.isNotEmpty
            ? state.roomPhotoUrls.first
            : null,
        imageUrls: state.roomPhotoUrls,
        availableFrom: state.availableFrom,
        genderPreference: state.genderPreference,
        sharingType: state.roomType,
        societyType: state.societyType,
        societyAmenities: state.societyAmenities.toList(growable: false),
        societyVibeTags: state.societyVibeTags.toList(growable: false),
        videoTourUrl: state.videoTourUrl,
      );

      // Submit the listing — the caller reads the returned ID for navigation.
      final listingId = await ref
          .read(listingsRepositoryProvider)
          .createListing(request);

      // Invalidate discover cache
      ref.invalidate(discoverListingsProvider);

      await ref.read(bootstrapControllerProvider.notifier).load();

      // Clear draft on success
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefsKey:step');

      state = state.copyWith(isSubmitting: false);
      return listingId;
    } catch (e) {
      final message = switch (e) {
        final AppFailure f => f.label,
        _ => 'Failed to create listing',
      };
      state = state.copyWith(isSubmitting: false, submitError: message);
      return null;
    }
  }

  // ── Draft management ─────────────────────────────────────────────

  void clearDraft() {
    state = const ListingDraftState();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.remove('$_prefsKey:step'),
    );
  }
}

final listingDraftControllerProvider =
    NotifierProvider<ListingDraftController, ListingDraftState>(
      ListingDraftController.new,
    );
