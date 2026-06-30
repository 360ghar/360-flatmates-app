import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/endpoints.dart';
import '../../core/providers.dart';
import '../../core/utils/paged_envelope.dart';
import '../discover/data/property_listing_dto.dart';
import '../discover/discover_repository.dart';

class ListingCreateRequest {
  const ListingCreateRequest({
    required this.title,
    required this.description,
    required this.city,
    required this.locality,
    required this.subLocality,
    required this.monthlyRent,
    required this.securityDeposit,
    required this.maintenanceCharges,
    required this.areaSqft,
    required this.bedrooms,
    required this.bathrooms,
    required this.features,
    required this.tags,
    required this.mainImageUrl,
    required this.imageUrls,
    required this.availableFrom,
    required this.genderPreference,
    required this.sharingType,
    required this.societyType,
    required this.societyAmenities,
    required this.societyVibeTags,
    this.videoTourUrl,
  });

  final String title;
  final String? description;
  final String? city;
  final String? locality;
  final String? subLocality;
  final double monthlyRent;
  final double? securityDeposit;
  final double? maintenanceCharges;
  final double? areaSqft;
  final int? bedrooms;
  final int? bathrooms;
  final List<String> features;
  final List<String> tags;
  final String? mainImageUrl;
  final List<String> imageUrls;
  final DateTime? availableFrom;
  final String genderPreference;
  final String sharingType;
  final String societyType;
  final List<String> societyAmenities;
  final List<String> societyVibeTags;
  final String? videoTourUrl;

  Map<String, dynamic> toJson() {
    final fullAddress = [
      if (subLocality != null && subLocality!.trim().isNotEmpty)
        subLocality!.trim(),
      if (locality != null && locality!.trim().isNotEmpty) locality!.trim(),
      if (city != null && city!.trim().isNotEmpty) city!.trim(),
    ].join(', ');

    final preferences = <String, dynamic>{
      'gender_preference': genderPreference,
      'sharing_type': sharingType,
      'society_type': societyType,
      'society_amenities': societyAmenities,
      'society_vibes': societyVibeTags,
    };

    if (videoTourUrl != null) {
      preferences['video_tour_url'] = videoTourUrl;
    }

    return {
      'title': title,
      'description': description,
      'property_type': 'flatmate',
      'purpose': 'rent',
      'base_price': monthlyRent,
      'monthly_rent': monthlyRent,
      'city': city,
      'locality': locality,
      'sub_locality': subLocality,
      'full_address': fullAddress.isEmpty ? null : fullAddress,
      'area_sqft': areaSqft,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'security_deposit': securityDeposit,
      'maintenance_charges': maintenanceCharges,
      'features': features.isEmpty ? null : features,
      'tags': tags.isEmpty ? null : tags,
      'main_image_url': mainImageUrl,
      'image_urls': imageUrls.isEmpty ? null : imageUrls,
      'available_from': availableFrom?.toUtc().toIso8601String(),
      'listing_preferences': preferences,
    };
  }
}

class ListingsRepository {
  const ListingsRepository(this._ref);

  final Ref _ref;

  Future<int?> createListing(ListingCreateRequest request) async {
    final response = await _ref
        .watch(apiClientProvider)
        .post(FlatmatesEndpoints.properties, data: request.toJson());
    final rawData = response.data;
    final data = Map<String, dynamic>.from(rawData is Map ? rawData : const {});
    return (data['id'] as num?)?.toInt();
  }

  /// Updates an existing listing in place (PUT) so editing never creates a
  /// duplicate. Returns the listing id on success.
  ///
  /// The PUT body keeps editable `listing_preferences` and strips null fields
  /// so the edit only touches values the form owns.
  Future<int?> updateListing(
    int listingId,
    ListingCreateRequest request,
  ) async {
    final body = Map<String, dynamic>.from(request.toJson())
      ..removeWhere((_, value) => value == null);
    final response = await _ref
        .watch(apiClientProvider)
        .put(FlatmatesEndpoints.property(listingId), data: body);
    final rawData = response.data;
    final data = Map<String, dynamic>.from(rawData is Map ? rawData : const {});
    return (data['id'] as num?)?.toInt() ?? listingId;
  }

  /// Fetches a single page of the user's listings using cursor pagination.
  ///
  /// The backend wraps all list endpoints in
  /// `{ items, next_cursor, has_more, limit }`.
  Future<({List<PropertyListing> items, String? nextCursor, bool hasMore})>
  fetchMyListingsPage({String? cursor, int limit = 20}) async {
    final queryParameters = <String, dynamic>{'limit': limit};
    if (cursor != null && cursor.isNotEmpty) {
      queryParameters['cursor'] = cursor;
    }
    final response = await _ref
        .watch(apiClientProvider)
        .get(FlatmatesEndpoints.myProperties, queryParameters: queryParameters);
    final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
    final page = parsePagedEnvelope(
      data,
      PropertyListingDto.fromJson,
      label: 'myListings',
    );
    final filtered = page.items
        .where((listing) {
          final type = listing.propertyType;
          return type == null || type == 'flatmate' || type == 'pg';
        })
        .toList(growable: false);
    return (
      items: filtered,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  /// Backwards-compatible helper aggregating all pages into a single list.
  Future<List<PropertyListing>> fetchMyListings({int limit = 20}) async {
    final allItems = <PropertyListing>[];
    String? cursor;
    while (true) {
      final page = await fetchMyListingsPage(cursor: cursor, limit: limit);
      allItems.addAll(page.items);
      if (!page.hasMore ||
          page.nextCursor == null ||
          page.nextCursor!.isEmpty) {
        break;
      }
      cursor = page.nextCursor;
    }
    return allItems;
  }

  Future<void> togglePause(int listingId, {required bool paused}) async {
    await _ref
        .watch(apiClientProvider)
        .put(
          FlatmatesEndpoints.property(listingId),
          data: {
            'listing_preferences': {
              'moderation_status': paused ? 'live' : 'paused',
            },
          },
        );
  }
}

final listingsRepositoryProvider = Provider<ListingsRepository>(
  (ref) => ListingsRepository(ref),
);

final myListingsProvider = FutureProvider<List<PropertyListing>>(
  (ref) => ref.watch(listingsRepositoryProvider).fetchMyListings(),
);
