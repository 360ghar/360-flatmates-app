import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/storage/image_upload_service.dart' as uploads;
import '../../bootstrap/bootstrap_controller.dart';
import '../../discover/application/discover_feed_controller.dart';
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
  /// Returns the listing id on success.
  Future<int?> submit({
    required ListingCreateRequest request,
    required int? editingId,
  }) async {
    final listingId = editingId != null
        ? await _listingsRepo.updateListing(editingId, request)
        : await _listingsRepo.createListing(request);

    unawaited(_ref.read(discoverFeedControllerProvider.notifier).refresh());
    _ref.invalidate(myListingsProvider);
    _ref.invalidate(myListingsListControllerProvider);
    await _ref.read(bootstrapControllerProvider.notifier).refresh();

    return listingId;
  }
}

final createListingControllerProvider = Provider<CreateListingController>(
  (ref) => CreateListingController(ref),
);
