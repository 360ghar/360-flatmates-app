import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/endpoints.dart';
import '../../core/providers.dart';
import '../bootstrap/bootstrap_controller.dart';
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
      normalizeMoveInFilter(moveInTimeline) == null;

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
    final queryParameters = <String, dynamic>{
      'property_type': 'flatmate',
      'purpose': 'rent',
      'offset': offset,
      'limit': limit,
    };
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
    final properties = (data['properties'] as List? ?? const []);
    final listings = properties
        .whereType<Map>()
        .map(
          (item) =>
              PropertyListingDto.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();

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
      return _applyDealBreakerFilter(
        moveInFiltered,
        userNonNegotiables,
        currentUser,
      );
    }

    return moveInFiltered;
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

  Future<int?> likeListing(int propertyId) async {
    final response = await _ref
        .read(apiClientProvider)
        .post(
          FlatmatesEndpoints.swipes,
          data: {
            'target_type': 'property',
            'action': 'like',
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
}

final discoverRepositoryProvider = Provider<DiscoverRepository>(
  (ref) => DiscoverRepository(ref),
);

final discoverFiltersProvider = StateProvider<DiscoverFilters?>((ref) => null);

final discoverListingsProvider = FutureProvider<List<PropertyListing>>((ref) {
  final profile = ref.watch(
    bootstrapControllerProvider.select((s) => s.valueOrNull?.profile),
  );
  final filters = ref.watch(discoverFiltersProvider);
  return ref
      .watch(discoverRepositoryProvider)
      .fetchListings(currentUser: profile, filters: filters);
});

final propertyListingProvider = FutureProvider.family<PropertyListing, int>(
  (ref, propertyId) =>
      ref.watch(discoverRepositoryProvider).fetchListing(propertyId),
);
