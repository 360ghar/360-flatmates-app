import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/storage/image_upload_service.dart' as uploads;
import '../../discover/application/discover_feed_controller.dart';
import '../../discover/application/property_listing_seed_store.dart';
import '../../discover/discover_repository.dart';
import '../listings_repository.dart';
import '../my_listings_controller.dart';

/// Application-layer controller for the create/edit listing flow.
///
/// Encapsulates repository and upload-service orchestration so the page widget
/// never calls data sources directly. UI state (step, flags, form fields) stays
/// in the widget layer via Riverpod providers.
class CreateListingController {
  CreateListingController(this._ref);

  final Ref _ref;

  uploads.ImageUploadService get _imageService =>
      _ref.read(uploads.imageUploadServiceProvider);
  ListingsRepository get _listingsRepo => _ref.read(listingsRepositoryProvider);
  DiscoverRepository get _discoverRepo => _ref.read(discoverRepositoryProvider);

  /// Picks up to [limit] images from the gallery.
  Future<List<File>> pickRoomPhotos({required int limit}) =>
      _imageService.pickImages(limit: limit);

  /// Uploads a single room photo. Throws [UploadFailure] so the UI can
  /// surface the reason per file without aborting the rest of the batch.
  Future<String> uploadRoomPhoto(File file) async {
    final result = await _imageService.uploadListingPhoto(file);
    switch (result) {
      case uploads.UploadSuccess(:final url):
        return url;
      case uploads.UploadFailure(:final reason):
        throw UploadFailure(reason: reason);
    }
  }

  /// Loads an existing listing for edit mode.
  Future<PropertyListing> loadListingForEdit(int listingId) =>
      _discoverRepo.fetchListing(listingId);

  /// Creates or updates a listing and refreshes dependent providers.
  /// Returns the listing id and the parsed [PropertyListing] from the
  /// mutation response when available (create and update).
  Future<({int? id, PropertyListing? listing})> submit({
    required ListingCreateRequest request,
    required int? editingId,
  }) async {
    final result = editingId != null
        ? await _listingsRepo.updateListing(editingId, request)
        : await _listingsRepo.createListing(request);

    var listing = result.listing;
    final id = result.id;

    // Prefer a confirmed GET so owner pending_review rows are fully hydrated
    // and we know the listing is readable for this account.
    if (id != null) {
      listing = await _listingsRepo.confirmListing(id, fallback: listing);
    }

    if (listing == null && id != null) {
      // Last-resort stub from form fields so Manage never loses the row.
      listing = PropertyListing(
        id: id,
        ownerId: null,
        propertyType: 'flatmate',
        title: request.title,
        description: request.description,
        city: request.city,
        state: null,
        locality: request.locality,
        subLocality: request.subLocality,
        latitude: null,
        longitude: null,
        monthlyRent: request.monthlyRent,
        mainImageUrl: request.mainImageUrl,
        imageUrls: request.imageUrls,
        areaSqft: request.areaSqft,
        bedrooms: request.bedrooms,
        bathrooms: request.bathrooms,
        features: request.features,
        tags: request.tags,
        ownerName: null,
        availableFrom: request.availableFrom,
        genderPreference: request.genderPreference,
        sharingType: request.sharingType,
        videoTourUrl: request.videoTourUrl,
        securityDeposit: request.securityDeposit,
        maintenanceCharges: request.maintenanceCharges,
        floorNumber: request.floorNumber,
        totalFloors: request.totalFloors,
        interestCount: 0,
        viewCount: 0,
        likeCount: 0,
        isAvailable: false,
        createdAt: DateTime.now().toUtc(),
        status: 'pending_review',
        preferences: {
          'moderation_status': 'pending_review',
          if (request.electricityIncluded != null)
            'electricity_included': request.electricityIncluded,
          if (request.electricityEst != null)
            'electricity_est': request.electricityEst,
          if (request.cookCost != null) 'cook_cost': request.cookCost,
          if (request.maidCost != null) 'maid_cost': request.maidCost,
          if (request.setupCost != null) 'setup_cost': request.setupCost,
          if (request.ageMin != null) 'age_min': request.ageMin,
          if (request.ageMax != null) 'age_max': request.ageMax,
          if (request.nonNegotiables.isNotEmpty)
            'non_negotiables': request.nonNegotiables,
        },
      );
    }

    if (listing != null) {
      // Only fill a missing moderation status — never rewrite live/available
      // lifecycle rows to pending_review after edit/confirm.
      final statusMissing =
          listing.status == null || listing.status!.trim().isEmpty;
      if (statusMissing &&
          !listing.isUnderReview &&
          !listing.isRejected &&
          !listing.isLive) {
        listing = listing.copyWith(
          status: 'pending_review',
          preferences: {
            ...?listing.preferences,
            'moderation_status': 'pending_review',
          },
        );
      }
      _ref.read(propertyListingSeedStoreProvider.notifier).put(listing);

      // AWAIT disk cache BEFORE list refresh — unawaited write raced with
      // refresh and left Manage empty after restart.
      await _listingsRepo.cacheOwnerListing(listing);

      _ref
          .read(myListingsListControllerProvider.notifier)
          .upsertOptimistically(listing);
    }

    // List refresh merges server + cache; do not block navigation on feed.
    unawaited(_refreshAfterSubmit());
    return (id: id, listing: listing);
  }

  Future<void> _refreshAfterSubmit() async {
    try {
      unawaited(_ref.read(discoverFeedControllerProvider.notifier).refresh());
      _ref.invalidate(myListingsProvider);
      await _ref.read(myListingsListControllerProvider.notifier).refresh();
    } catch (e) {
      debugPrint('CreateListingController._refreshAfterSubmit: $e');
    }
  }
}

final createListingControllerProvider = Provider<CreateListingController>(
  (ref) => CreateListingController(ref),
);
