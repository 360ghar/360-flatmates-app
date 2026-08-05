import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/endpoints.dart';
import '../../core/providers.dart';
import '../../core/providers/mutable_notifier.dart';
import '../../core/utils/safe_json_list.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../location/application/location_controller.dart';
import 'application/discover_feed_controller.dart';
import 'application/move_in_filter.dart';
import 'application/property_listing_seed_store.dart';
import 'data/property_listing_dto.dart';
import 'domain/property_listing.dart';
import '../chats/application/cursor_list_controller.dart';
import '../chats/chats_repository.dart';

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
    this.furnishing = const [],
    this.kitchenType = const [],
    this.ventilationType = const [],
    this.amenities = const [],
    this.windowsMin,
    this.hasLift,
    this.bedrooms,
    this.pets,
    this.smoking,
    this.drinking,
    this.vibe,
    this.moveInTimeline,
    this.ageMin,
    this.ageMax,
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
  final List<String> furnishing;
  final List<String> kitchenType;
  final List<String> ventilationType;
  final List<String> amenities;
  final int? windowsMin;
  final bool? hasLift;
  final int? bedrooms;
  final String? pets;
  final String? smoking;
  final String? drinking;
  final String? vibe;
  final String? moveInTimeline;
  final int? ageMin;
  final int? ageMax;
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
      furnishing.isEmpty &&
      kitchenType.isEmpty &&
      ventilationType.isEmpty &&
      amenities.isEmpty &&
      windowsMin == null &&
      hasLift == null &&
      bedrooms == null &&
      pets == null &&
      smoking == null &&
      drinking == null &&
      vibe == null &&
      ageMin == null &&
      ageMax == null &&
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
    List<String>? furnishing,
    List<String>? kitchenType,
    List<String>? ventilationType,
    List<String>? amenities,
    int? windowsMin,
    bool? hasLift,
    int? bedrooms,
    String? pets,
    String? smoking,
    String? drinking,
    String? vibe,
    String? moveInTimeline,
    int? ageMin,
    int? ageMax,
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
    bool clearDrinking = false,
    bool clearVibe = false,
    bool clearMoveInTimeline = false,
    bool clearLatitude = false,
    bool clearLongitude = false,
    bool clearRadiusKm = false,
    bool clearWindowsMin = false,
    bool clearHasLift = false,
    bool clearAgeMin = false,
    bool clearAgeMax = false,
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
      furnishing: furnishing ?? this.furnishing,
      kitchenType: kitchenType ?? this.kitchenType,
      ventilationType: ventilationType ?? this.ventilationType,
      amenities: amenities ?? this.amenities,
      windowsMin: clearWindowsMin ? null : (windowsMin ?? this.windowsMin),
      hasLift: clearHasLift ? null : (hasLift ?? this.hasLift),
      bedrooms: clearBedrooms ? null : (bedrooms ?? this.bedrooms),
      pets: clearPets ? null : (pets ?? this.pets),
      smoking: clearSmoking ? null : (smoking ?? this.smoking),
      drinking: clearDrinking ? null : (drinking ?? this.drinking),
      vibe: clearVibe ? null : (vibe ?? this.vibe),
      moveInTimeline: clearMoveInTimeline
          ? null
          : (moveInTimeline ?? this.moveInTimeline),
      ageMin: clearAgeMin ? null : (ageMin ?? this.ageMin),
      ageMax: clearAgeMax ? null : (ageMax ?? this.ageMax),
      latitude: clearLatitude ? null : (latitude ?? this.latitude),
      longitude: clearLongitude ? null : (longitude ?? this.longitude),
      radiusKm: clearRadiusKm ? null : (radiusKm ?? this.radiusKm),
    );
  }
}

class DiscoverRepository {
  DiscoverRepository(this._ref);

  final Ref _ref;

  /// Listing ids with a like-toggle POST currently in flight. Rapid re-taps on
  /// the same listing are dropped while its toggle is pending, so the optimistic
  /// heart and the server cannot diverge and `likeCount` cannot drift ±1/tap.
  final Set<int> _pendingLikeIds = <int>{};

  /// Reserves the like-toggle slot for [propertyId]. Returns false if a toggle
  /// for this id is already in flight, in which case the caller must drop the
  /// tap (before touching any optimistic state).
  bool reserveLikeToggle(int propertyId) => _pendingLikeIds.add(propertyId);

  /// Releases the like-toggle slot once the POST has settled (success or error).
  void releaseLikeToggle(int propertyId) => _pendingLikeIds.remove(propertyId);

  Future<List<PropertyListing>> fetchListings({
    String? cursor,
    int limit = 20,
    FlatmatesProfileModel? currentUser,
    DiscoverFilters? filters,
  }) async {
    final page = await fetchListingsPage(
      cursor: cursor,
      limit: limit,
      currentUser: currentUser,
      filters: filters,
    );
    return page.items;
  }

  /// Fetches one page of listings. [rawCount] is the number of items the
  /// server returned BEFORE client-side filtering — pagination (cursor,
  /// hasMore) must be driven by the backend cursor, not by [items].length.
  Future<({List<PropertyListing> items, int rawCount, String? nextCursor})>
  fetchListingsPage({
    String? cursor,
    int limit = 20,
    FlatmatesProfileModel? currentUser,
    DiscoverFilters? filters,
  }) async {
    final queryParameters = <String, dynamic>{
      'property_type': 'flatmate',
      'purpose': 'rent',
      'limit': limit,
    };
    if (cursor != null && cursor.isNotEmpty) {
      queryParameters['cursor'] = cursor;
    }
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
        queryParameters['bedrooms_min'] = filters.bedrooms;
        queryParameters['bedrooms_max'] = filters.bedrooms;
      }
      if (filters.features.isNotEmpty) {
        queryParameters['features'] = filters.features;
      }
      if (filters.furnishing.isNotEmpty) {
        queryParameters['furnishing'] = filters.furnishing;
      }
      if (filters.kitchenType.isNotEmpty) {
        queryParameters['kitchen_type'] = filters.kitchenType;
      }
      if (filters.ventilationType.isNotEmpty) {
        queryParameters['ventilation_type'] = filters.ventilationType;
      }
      if (filters.amenities.isNotEmpty) {
        queryParameters['amenities'] = filters.amenities;
      }
      if (filters.windowsMin != null) {
        queryParameters['windows_min'] = filters.windowsMin;
      }
      if (filters.hasLift != null) {
        queryParameters['has_lift'] = filters.hasLift;
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
      data['items'] as List?,
      PropertyListingDto.fromJson,
      label: 'discoverFeed',
    );
    final nextCursor = data['next_cursor'] as String?;

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
        nextCursor: nextCursor,
      );
    }

    return (
      items: moveInFiltered,
      rawCount: listings.length,
      nextCursor: nextCursor,
    );
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

  /// Resolves a listing's smoking value, preferring the split field and
  /// falling back to the legacy combined [smoking_drinking] value.
  String? _listingSmoking(Map<String, dynamic>? preferences) {
    final direct = preferences?['smoking'];
    if (direct is String && direct.trim().isNotEmpty) return direct.trim();
    return switch (preferences?['smoking_drinking']) {
      'smoke_outside' || 'both_fine' => 'regularly',
      _ => null,
    };
  }

  /// Resolves a listing's drinking value, preferring the split field and
  /// falling back to the legacy combined [smoking_drinking] value.
  String? _listingDrinking(Map<String, dynamic>? preferences) {
    final direct = preferences?['drinking'];
    if (direct is String && direct.trim().isNotEmpty) return direct.trim();
    return switch (preferences?['smoking_drinking']) {
      'drink_occasionally' => 'occasionally',
      // 'both_fine' resolves to occasional drinking, matching the web
      // onboarding-store migration (smoking 'regularly' + drinking
      // 'occasionally') so both surfaces agree on the legacy value.
      'both_fine' => 'occasionally',
      _ => null,
    };
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
            final listingSmoking = _listingSmoking(listing.preferences);
            if (listingSmoking == 'occasionally' ||
                listingSmoking == 'regularly') {
              return false;
            }
            break;
          case 'no_drinking':
            final listingDrinking = _listingDrinking(listing.preferences);
            if (listingDrinking == 'occasionally' ||
                listingDrinking == 'regularly') {
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

/// Shared discover/map/swipe filter selection (product state).
final discoverFiltersProvider =
    NotifierProvider<MutableNotifier<DiscoverFilters?>, DiscoverFilters?>(
      () => MutableNotifier(null),
    );

/// Currently selected property on the map carousel (route-scoped).
final selectedPropertyProvider =
    NotifierProvider.autoDispose<
      AutoDisposeMutableNotifier<PropertyListing?>,
      PropertyListing?
    >(() => AutoDisposeMutableNotifier(null));

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

/// Owns the detail-page state for a single listing so that likes can be
/// applied optimistically (instant heart flip) with rollback on failure,
/// instead of a full network refetch round-trip.
class PropertyListingController
    extends FamilyAsyncNotifier<PropertyListing, int> {
  @override
  FutureOr<PropertyListing> build(int arg) async {
    final seeded = ref.read(propertyListingSeedStoreProvider.notifier).get(arg);

    // Under-review / rejected seeds: show immediately. A blocking GET can hang
    // (timeout → false "no internet") or 404 for non-owners; reconcile in the
    // background when the owner is authenticated.
    if (seeded != null && (seeded.isUnderReview || seeded.isRejected)) {
      unawaited(_reconcileInBackground(arg));
      return seeded;
    }

    try {
      final fresh = await ref
          .watch(discoverRepositoryProvider)
          .fetchListing(arg);
      // Keep seed warm for later router rebuilds / owner preview.
      ref.read(propertyListingSeedStoreProvider.notifier).put(fresh);
      return fresh;
    } catch (e) {
      // Pending listings 404 for non-owners (and optional-auth races). Serve
      // the durable seed so View Listing after create still works.
      if (seeded != null) return seeded;
      rethrow;
    }
  }

  Future<void> _reconcileInBackground(int listingId) async {
    try {
      final fresh = await ref
          .read(discoverRepositoryProvider)
          .fetchListing(listingId);
      ref.read(propertyListingSeedStoreProvider.notifier).put(fresh);
      // Only update if this family instance is still alive.
      state = AsyncData(fresh);
    } catch (e) {
      // Keep seed — expected for non-owners / flaky transport.
      debugPrint('PropertyListingController._reconcileInBackground: $e');
    }
  }

  /// Seeds the provider with a pre-loaded listing (e.g. from the POST response
  /// right after creation). GET is still attempted on build; seed is the
  /// fallback when the public endpoint hides pending listings.
  void seed(PropertyListing listing) {
    ref.read(propertyListingSeedStoreProvider.notifier).put(listing);
    state = AsyncData(listing);
  }

  /// Toggles the like state optimistically. Returns the conversation_id (or
  /// null) on success. Rolls back and rethrows on failure so callers can toast.
  Future<int?> toggleLike() async {
    final current = state.valueOrNull;
    if (current == null) return null;
    final newLiked = !(current.liked ?? false);
    return _applyLiked(current, newLiked);
  }

  /// Ensures the listing is liked (used by contact / schedule-visit flows that
  /// imply a like). Optimistically likes if not already liked. Always returns
  /// the conversation_id from the backend (or null).
  Future<int?> ensureLiked([PropertyListing? listing]) async {
    // Prefer authoritative provider state; the argument covers seed-only
    // callers where the family has no value yet.
    final current = state.valueOrNull ?? listing;
    if (current == null) return null;
    if (current.liked ?? false) {
      // Already liked; still hit the backend to obtain a conversation_id.
      return ref.read(discoverRepositoryProvider).setLiked(current.id, true);
    }
    return _applyLiked(current, true);
  }

  Future<int?> _applyLiked(PropertyListing current, bool newLiked) async {
    final repo = ref.read(discoverRepositoryProvider);
    // Drop a tap that lands while a toggle for this listing is already in
    // flight. The guard sits BEFORE the optimistic mutation so a dropped tap
    // never flips the heart or bumps `likeCount` — that is what keeps the
    // client and server from diverging under rapid re-toggles.
    if (!repo.reserveLikeToggle(current.id)) {
      return null;
    }
    // Apply optimistic state immediately so the heart responds instantly.
    // `likeCount` here is a client-side estimate reflecting the viewer's own
    // action; it reconciles with the authoritative server count on the next
    // full refetch (pull-to-refresh or re-navigation). We deliberately do NOT
    // refetch here — a background reconcile would race against rapid re-toggles
    // and could clobber a newer optimistic value with a stale server count.
    state = AsyncData(
      current.copyWith(
        liked: newLiked,
        likeCount: current.likeCount + (newLiked ? 1 : -1),
      ),
    );
    try {
      final cid = await repo.setLiked(current.id, newLiked);

      final outgoing = ref.read(outgoingLikesListControllerProvider.notifier);
      if (newLiked) {
        outgoing.upsertOutgoingLike(
          OutgoingLikeModel.fromPropertyListing(current),
        );
      } else {
        outgoing.removeOptimistically(
          OutgoingLikeModel.fromPropertyListing(current),
        );
      }
      return cid;
    } catch (e) {
      // Rollback on failure.
      state = AsyncData(current);
      rethrow;
    } finally {
      repo.releaseLikeToggle(current.id);
    }
  }
}

final propertyListingProvider =
    AsyncNotifierProvider.family<
      PropertyListingController,
      PropertyListing,
      int
    >(PropertyListingController.new);
