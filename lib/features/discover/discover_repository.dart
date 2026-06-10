import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/endpoints.dart';
import '../../core/providers.dart';
import '../../core/utils/safe_json_list.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../location/application/location_controller.dart';
import 'application/discover_feed_controller.dart';
import 'application/move_in_filter.dart';
import 'data/property_listing_dto.dart';
import 'domain/property_listing.dart';

export 'domain/property_listing.dart';

class DiscoverFilters {
  const DiscoverFilters({
    this.query,
    this.location,
    this.priceMin,
    this.priceMax,
    this.sharingType,
    this.genderPreference,
    this.features = const [],
    this.bedrooms,
    this.pets,
    this.smoking,
    this.vibe,
    this.moveInTimeline,
    this.latitude,
    this.longitude,
    this.radiusKm,
  });

  final String? query;
  final String? location;
  final double? priceMin;
  final double? priceMax;
  final String? sharingType;
  final String? genderPreference;
  final List<String> features;
  final int? bedrooms;
  final String? pets;
  final String? smoking;
  final String? vibe;
  final String? moveInTimeline;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;

  bool get hasGeoLocation => latitude != null && longitude != null;

  bool get isEmpty =>
      (query == null || query!.trim().isEmpty) &&
      (location == null || location!.trim().isEmpty) &&
      priceMin == null &&
      priceMax == null &&
      sharingType == null &&
      genderPreference == null &&
      features.isEmpty &&
      bedrooms == null &&
      pets == null &&
      smoking == null &&
      vibe == null &&
      normalizeMoveInFilter(moveInTimeline) == null &&
      latitude == null &&
      longitude == null &&
      radiusKm == null;

  DiscoverFilters copyWith({
    String? query,
    String? location,
    double? priceMin,
    double? priceMax,
    String? sharingType,
    String? genderPreference,
    List<String>? features,
    int? bedrooms,
    String? pets,
    String? smoking,
    String? vibe,
    String? moveInTimeline,
    double? latitude,
    double? longitude,
    double? radiusKm,
    bool clearQuery = false,
    bool clearBedrooms = false,
    bool clearLocation = false,
    bool clearPriceMin = false,
    bool clearPriceMax = false,
    bool clearSharingType = false,
    bool clearGenderPreference = false,
    bool clearPets = false,
    bool clearSmoking = false,
    bool clearVibe = false,
    bool clearMoveInTimeline = false,
    bool clearLatitude = false,
    bool clearLongitude = false,
    bool clearRadiusKm = false,
  }) {
    return DiscoverFilters(
      query: clearQuery ? null : (query ?? this.query),
      location: clearLocation ? null : (location ?? this.location),
      priceMin: clearPriceMin ? null : (priceMin ?? this.priceMin),
      priceMax: clearPriceMax ? null : (priceMax ?? this.priceMax),
      sharingType: clearSharingType ? null : (sharingType ?? this.sharingType),
      genderPreference: clearGenderPreference
          ? null
          : (genderPreference ?? this.genderPreference),
      features: features ?? this.features,
      bedrooms: clearBedrooms ? null : (bedrooms ?? this.bedrooms),
      pets: clearPets ? null : (pets ?? this.pets),
      smoking: clearSmoking ? null : (smoking ?? this.smoking),
      vibe: clearVibe ? null : (vibe ?? this.vibe),
      moveInTimeline: clearMoveInTimeline
          ? null
          : (moveInTimeline ?? this.moveInTimeline),
      latitude: clearLatitude ? null : (latitude ?? this.latitude),
      longitude: clearLongitude ? null : (longitude ?? this.longitude),
      radiusKm: clearRadiusKm ? null : (radiusKm ?? this.radiusKm),
    );
  }
}

class DiscoverRepository {
  const DiscoverRepository(this._ref);

  final Ref _ref;

  Future<List<PropertyListing>> fetchListings({
    int offset = 0,
    int limit = 20,
    FlatmatesProfileModel? currentUser,
    DiscoverFilters? filters,
  }) async {
    final page = await fetchListingsPage(
      offset: offset,
      limit: limit,
      currentUser: currentUser,
      filters: filters,
    );
    return page.items;
  }

  /// Fetches one page of listings. [rawCount] is the number of items the
  /// server returned BEFORE client-side filtering — pagination (offset,
  /// hasMore) must be driven by it, not by [items].length.
  Future<({List<PropertyListing> items, int rawCount})> fetchListingsPage({
    int offset = 0,
    int limit = 20,
    FlatmatesProfileModel? currentUser,
    DiscoverFilters? filters,
  }) async {
    final queryParameters = <String, dynamic>{
      'property_type': 'flatmate',
      'purpose': 'rent',
      'offset': offset,
      'limit': limit,
    };
    if (filters?.hasGeoLocation ?? false) {
      final f = filters!;
      queryParameters['lat'] = f.latitude!.toStringAsFixed(6);
      queryParameters['lng'] = f.longitude!.toStringAsFixed(6);
      if (f.radiusKm != null) {
        queryParameters['radius'] = f.radiusKm!.round();
      }
    }
    if (filters != null && !filters.isEmpty) {
      final query = [
        filters.query,
        filters.location,
      ].where((value) => value != null && value.trim().isNotEmpty).join(' ');
      if (query.isNotEmpty) {
        queryParameters['q'] = query;
      }
      if (filters.priceMin != null) {
        queryParameters['price_min'] = filters.priceMin;
      }
      if (filters.priceMax != null) {
        queryParameters['price_max'] = filters.priceMax;
      }
      if (filters.sharingType != null) {
        queryParameters['sharing_type'] = filters.sharingType;
      }
      if (filters.genderPreference != null) {
        queryParameters['gender_preference'] = filters.genderPreference;
      }
      if (filters.bedrooms != null) {
        queryParameters['bedrooms'] = filters.bedrooms;
      }
      if (filters.features.isNotEmpty) {
        queryParameters['features'] = filters.features;
      }
      if (filters.pets != null) {
        queryParameters['pets'] = filters.pets;
      }
      if (filters.smoking != null) {
        queryParameters['smoking'] = filters.smoking;
      }
      final moveIn = moveInFilterQueryValue(filters.moveInTimeline);
      if (moveIn != null) {
        queryParameters['move_in'] = moveIn;
      }
    }
    final response = await _ref
        .read(apiClientProvider)
        .get(FlatmatesEndpoints.properties, queryParameters: queryParameters);
    final responseData = response.data;
    final data = Map<String, dynamic>.from(
      responseData is Map ? responseData : const {},
    );
    final listings = safeJsonList(
      data['properties'] as List?,
      PropertyListingDto.fromJson,
      label: 'discoverFeed',
    );

    final moveInFiltered = filters == null
        ? listings
        : listings
              .where(
                (listing) => listingMatchesMoveInFilter(
                  listing.availableFrom,
                  filters.moveInTimeline,
                ),
              )
              .toList();

    if (currentUser != null) {
      final userNonNegotiables = _extractUserNonNegotiables(
        currentUser.preferences,
      );
      return (
        items: _applyDealBreakerFilter(
          moveInFiltered,
          userNonNegotiables,
          currentUser,
        ),
        rawCount: listings.length,
      );
    }

    return (items: moveInFiltered, rawCount: listings.length);
  }

  Future<PropertyListing> fetchListing(int propertyId) async {
    final response = await _ref
        .read(apiClientProvider)
        .get(FlatmatesEndpoints.property(propertyId));
    final responseData = response.data;
    return PropertyListingDto.fromJson(
      Map<String, dynamic>.from(responseData is Map ? responseData : const {}),
    );
  }

  Future<Map<String, dynamic>?> fetchOwnerPeer(int ownerId) async {
    try {
      final response = await _ref
          .read(apiClientProvider)
          .get('${FlatmatesEndpoints.flatmatesProfiles}/$ownerId');
      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      debugPrint('DiscoverRepository.fetchOwnerPeer: $e');
      return null;
    }
  }

  Future<int?> setLiked(int propertyId, bool liked) async {
    final response = await _ref
        .read(apiClientProvider)
        .post(
          FlatmatesEndpoints.swipes,
          data: {
            'target_type': 'property',
            'action': liked ? 'like' : 'pass',
            'property_id': propertyId,
          },
        );
    final responseData = response.data;
    final data = Map<String, dynamic>.from(
      responseData is Map ? responseData : const {},
    );
    final rawConversationId = data['conversation_id'];
    return rawConversationId != null
        ? int.tryParse(rawConversationId.toString())
        : null;
  }

  Future<void> voteSocietyTag({
    required int listingId,
    required String tag,
    required String vote,
  }) async {
    await _ref
        .read(apiClientProvider)
        .post(
          FlatmatesEndpoints.societyTagVotes(listingId),
          data: {'tag': tag, 'vote': vote},
        );
  }

  Future<Map<String, dynamic>> scheduleVisit({
    required int propertyId,
    required int counterpartyUserId,
    required int conversationId,
    required DateTime scheduledDate,
    String? note,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .post(
          FlatmatesEndpoints.visits,
          data: {
            'property_id': propertyId,
            'scheduled_date': scheduledDate.toUtc().toIso8601String(),
            'visit_context': 'flatmate_meet',
            'counterparty_user_id': counterpartyUserId,
            'conversation_id': conversationId,
            if (note != null && note.trim().isNotEmpty)
              'special_requirements': note.trim(),
          },
        );
    final data = Map<String, dynamic>.from(
      response.data is Map ? response.data : const {},
    );
    return data;
  }

  List<String> _extractUserNonNegotiables(Map<String, dynamic>? preferences) {
    if (preferences == null) return const [];
    final raw = preferences['non_negotiables'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  List<PropertyListing> _applyDealBreakerFilter(
    List<PropertyListing> listings,
    List<String> userNonNegotiables,
    FlatmatesProfileModel? user,
  ) {
    if (userNonNegotiables.isEmpty) return listings;

    return listings.where((listing) {
      for (final neg in userNonNegotiables) {
        switch (neg) {
          case 'food_veg_only':
          case 'food_vegan_only':
            final listingFood =
                listing.preferences?['food_habits'] ?? 'no_preference';
            if (listingFood == 'non_vegetarian' || listingFood == 'non_veg') {
              return false;
            }
            break;
          case 'no_smoking':
            final listingSD =
                listing.preferences?['smoking_drinking'] ?? 'neither';
            if (listingSD == 'smoke_outside' || listingSD == 'both_fine') {
              return false;
            }
            break;
          case 'no_drinking':
            final listingSD =
                listing.preferences?['smoking_drinking'] ?? 'neither';
            if (listingSD == 'drink_occasionally' || listingSD == 'both_fine') {
              return false;
            }
            break;
          case 'no_overnight_guests':
            final listingGuests =
                listing.preferences?['guests_policy'] ?? 'occasional_ok';
            if (listingGuests == 'open_house' ||
                listingGuests == 'comfortable') {
              return false;
            }
            break;
          case 'no_pets':
            final hasPets =
                listing.preferences?['has_pets'] == true ||
                listing.preferences?['pets'] == true;
            if (hasPets) return false;
            break;
          case 'gender_female_only':
            if (listing.genderPreference != null &&
                listing.genderPreference != 'female' &&
                listing.genderPreference != 'any') {
              return false;
            }
            break;
          case 'gender_male_only':
            if (listing.genderPreference != null &&
                listing.genderPreference != 'male' &&
                listing.genderPreference != 'any') {
              return false;
            }
            break;
          case 'no_parties':
            final listingParties =
                listing.preferences?['parties'] ?? 'occasional';
            if (listingParties == 'party_friendly') return false;
            break;
          case 'min_tidy':
            final listingCleanliness =
                listing.preferences?['cleanliness'] ?? 'tidy';
            if (listingCleanliness == 'minimal') return false;
            break;
        }
      }
      return true;
    }).toList();
  }
}

final discoverRepositoryProvider = Provider<DiscoverRepository>(
  (ref) => DiscoverRepository(ref),
);

final discoverFiltersProvider = StateProvider<DiscoverFilters?>((ref) => null);

final selectedPropertyProvider = StateProvider.autoDispose<PropertyListing?>(
  (ref) => null,
);

final discoverListingsProvider = FutureProvider<List<PropertyListing>>((ref) {
  final profile = ref.watch(
    bootstrapControllerProvider.select((s) => s.valueOrNull?.profile),
  );
  final filters = ref.watch(discoverFiltersProvider);
  final selectedLocation = ref.watch(
    locationControllerProvider.select((s) => s.selectedLocation),
  );
  final effectiveFilters = filters?.hasGeoLocation == true
      ? filters
      : selectedLocation != null
      ? (filters ?? const DiscoverFilters()).copyWith(
          latitude: selectedLocation.latitude,
          longitude: selectedLocation.longitude,
          radiusKm: DiscoverFeedController.defaultLocationRadiusKm,
        )
      : filters;
  return ref
      .watch(discoverRepositoryProvider)
      .fetchListings(currentUser: profile, filters: effectiveFilters);
});

final propertyListingProvider = FutureProvider.family<PropertyListing, int>(
  (ref, propertyId) =>
      ref.watch(discoverRepositoryProvider).fetchListing(propertyId),
);
