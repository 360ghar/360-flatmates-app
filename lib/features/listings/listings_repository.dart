import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/endpoints.dart';
import '../../core/domain/wire_enums.dart';
import '../../core/errors/app_failure.dart';
import '../../core/providers.dart';
import '../../core/storage/app_preferences.dart';
import '../../core/utils/paged_envelope.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../discover/data/property_listing_dto.dart';
import '../discover/discover_repository.dart';
import '../discover/domain/property_listing.dart';

/// The address a listing gets when the owner types no street: society,
/// locality and city, joined by commas. The form sends it as `full_address`, and
/// reads a stored `full_address` equal to it back as "no street typed".
String composeListingAddress({
  String? subLocality,
  String? locality,
  String? city,
}) => [
  if (subLocality != null && subLocality.trim().isNotEmpty) subLocality.trim(),
  if (locality != null && locality.trim().isNotEmpty) locality.trim(),
  if (city != null && city.trim().isNotEmpty) city.trim(),
].join(', ');

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
    this.bathrooms,
    this.furnishingLevel,
    this.videoTourUrl,
    this.fullAddress,
    this.floorNumber,
    this.totalFloors,
    this.ageMin,
    this.ageMax,
    this.nonNegotiables = const [],
    this.electricityIncluded,
    this.electricityEst,
    this.cookCost,
    this.maidCost,
    this.setupCost,
    this.kitchenType,
    this.ventilationType,
    this.windowsCount,
    this.ventilationShafts,
    this.otherCharges,
    this.otherChargesDescription,
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

  /// Null when the owner has not entered a count: the form has no control for
  /// it, and a placeholder stored as real listing data is worse than none.
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

  /// The furnishing level of the room, from the furnishing the owner picked.
  /// Sent as `listing_preferences.rooms[].furnishing_level` (the server derives
  /// the listing `furnishing_level` from the rooms) and as `furnishing_level`.
  final FurnishingLevel? furnishingLevel;
  final String? videoTourUrl;

  /// Street / full address collected in the form. Prefer over composed location.
  final String? fullAddress;
  final int? floorNumber;
  final int? totalFloors;

  /// Preferred roommate age range and hard filters. The backend keeps only the
  /// public `listing_preferences` keys of an owner write, so these are sent but
  /// not stored today (see the handoff note).
  final int? ageMin;
  final int? ageMax;
  final List<String> nonNegotiables;
  final String? electricityIncluded;
  final double? electricityEst;
  final double? cookCost;
  final double? maidCost;

  /// One-time setup cost. Sent TOP-LEVEL per the backend contract
  /// (`setup_cost`).
  final double? setupCost;
  final String? kitchenType;
  final String? ventilationType;
  final int? windowsCount;
  final int? ventilationShafts;
  final double? otherCharges;
  final String? otherChargesDescription;

  /// Top-level keys the form has a control for. On update, a blank control
  /// clears the stored value, so these are sent as an explicit `null` (or an
  /// empty list). Every other null key is left out: the form did not touch it
  /// (`area_sqft`, `bathrooms`, ...), and an absent key keeps its value.
  static const _clearableOnUpdate = {
    'description',
    'city',
    'locality',
    'sub_locality',
    'full_address',
    'floor_number',
    'total_floors',
    'security_deposit',
    'maintenance_charges',
    'available_from',
    'kitchen_type',
    'ventilation_type',
    'windows_count',
    'ventilation_shafts',
    'setup_cost',
    'other_charges',
    'other_charges_description',
    'video_tour_url',
    'furnishing_level',
    'main_image_url',
  };

  /// A date as `YYYY-MM-DD`, the format of every date-only field. The date is
  /// the one the owner picked (local), not a UTC conversion of it.
  static String dateOnly(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year.toString().padLeft(4, '0')}-$month-$day';
  }

  /// Every field with its form value. A blank control is `null` (or an empty
  /// list). [toJson] and [toUpdateJson] decide which of them are sent.
  Map<String, dynamic> _fields() {
    final composedAddress = composeListingAddress(
      subLocality: subLocality,
      locality: locality,
      city: city,
    );
    final street = fullAddress?.trim();
    final resolvedAddress = (street != null && street.isNotEmpty)
        ? street
        : composedAddress;

    // Only the keys the backend keeps for an owner write belong here. The
    // five preference fields the contract declares top-level (gender,
    // sharing type, society type, amenities, vibe tags) go top-level below.
    // The street address is the typed `full_address` field, not a preference.
    final preferences = <String, dynamic>{
      'video_tour_url': videoTourUrl,
      if (furnishingLevel != null)
        'rooms': [
          {'furnishing_level': furnishingLevel!.wire},
        ]
      else
        'rooms': const <Map<String, dynamic>>[],
      if (ageMin != null) 'preferred_age_min': ageMin,
      if (ageMax != null) 'preferred_age_max': ageMax,
      if (nonNegotiables.isNotEmpty) 'non_negotiables': nonNegotiables,
      if (electricityIncluded != null && electricityIncluded!.isNotEmpty)
        'electricity_included': electricityIncluded,
      'electricity_est': ?electricityEst,
      'cook_cost': ?cookCost,
      'maid_cost': ?maidCost,
    };

    return {
      'title': title,
      'description': description,
      'property_type': PropertyType.flatmate.wire,
      'purpose': PropertyPurpose.rent.wire,
      'base_price': monthlyRent,
      'monthly_rent': monthlyRent,
      'city': city,
      'locality': locality,
      'sub_locality': subLocality,
      'full_address': resolvedAddress.isEmpty ? null : resolvedAddress,
      'area_sqft': areaSqft,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'floor_number': floorNumber,
      'total_floors': totalFloors,
      'security_deposit': securityDeposit,
      'maintenance_charges': maintenanceCharges,
      'features': features,
      'tags': tags,
      'main_image_url': mainImageUrl,
      'image_urls': imageUrls,
      'available_from': availableFrom == null ? null : dateOnly(availableFrom!),
      'kitchen_type': KitchenType.fromJson(kitchenType)?.wire,
      'ventilation_type': VentilationType.fromJson(ventilationType)?.wire,
      'windows_count': windowsCount,
      'ventilation_shafts': ventilationShafts,
      'setup_cost': setupCost,
      'other_charges': otherCharges,
      'other_charges_description': otherChargesDescription,
      'video_tour_url': videoTourUrl,
      'furnishing_level': furnishingLevel?.wire,
      'gender_preference': ListingGenderPreference.fromJson(
        genderPreference,
      )?.wire,
      'sharing_type': ListingSharingType.fromJson(sharingType)?.wire,
      'society_type': societyType,
      'society_amenities': societyAmenities,
      'society_vibe_tags': societyVibeTags,
      'listing_preferences': preferences,
    };
  }

  /// The `POST /properties` body: only the keys that have a value.
  Map<String, dynamic> toJson() {
    final fields = _fields();
    final preferences = Map<String, dynamic>.from(
      fields['listing_preferences'] as Map,
    )..removeWhere((_, value) => value == null);
    // A new listing has no rooms to clear.
    if (furnishingLevel == null) preferences.remove('rooms');
    return {
      for (final entry in fields.entries)
        if (entry.value != null &&
            !(entry.value is List && (entry.value as List).isEmpty))
          entry.key: entry.key == 'listing_preferences'
              ? preferences
              : entry.value,
    };
  }

  /// The `PUT /properties/{id}` body (a patch). A blank control sends an
  /// explicit `null` (an empty list for a list) so the stored value is
  /// cleared; a key the form never touches is left out.
  Map<String, dynamic> toUpdateJson() {
    final fields = _fields();
    return {
      for (final entry in fields.entries)
        if (entry.value != null || _clearableOnUpdate.contains(entry.key))
          entry.key: entry.value,
    };
  }
}

class ListingsRepository {
  ListingsRepository(this._ref);

  final Ref _ref;

  /// Owner listings seen this session, per signed-in account. Kept in memory
  /// only: `GET /properties/me` answers `Cache-Control: private, no-store`, so
  /// its rows are never written to disk. The cache keeps a just-created
  /// pending listing on screen if the next server page lags, and serves the
  /// last rows on a transient failure. It is dropped on sign-out and when the
  /// account changes.
  final Map<int, List<PropertyListing>> _memoryCache = {};

  /// Prefix of the keys an earlier build wrote to disk (a cache with no
  /// account scope and no schema version). They are deleted, never read.
  static const _legacyDiskKeyPrefix = PrefKeys.legacyListingsCachePrefix;

  Future<({int? id, PropertyListing? listing})> createListing(
    ListingCreateRequest request,
  ) async {
    final response = await _ref
        .watch(apiClientProvider)
        .post(FlatmatesEndpoints.properties, data: request.toJson());
    return _parseListingMutationResponse(response.data, fallbackId: null);
  }

  /// Updates an existing listing in place (PUT) so editing never creates a
  /// duplicate. Returns the listing id and parsed body when available.
  Future<({int? id, PropertyListing? listing})> updateListing(
    int listingId,
    ListingCreateRequest request,
  ) async {
    final response = await _ref
        .watch(apiClientProvider)
        .put(
          FlatmatesEndpoints.property(listingId),
          data: request.toUpdateJson(),
        );
    return _parseListingMutationResponse(response.data, fallbackId: listingId);
  }

  /// Confirms a created listing via GET /properties/{id} (owner can read
  /// pending_review). Falls back to [fallback] if GET fails.
  Future<PropertyListing> confirmListing(
    int listingId, {
    PropertyListing? fallback,
  }) async {
    try {
      final response = await _ref
          .watch(apiClientProvider)
          .get(FlatmatesEndpoints.property(listingId));
      final data = _asResponseMap(response.data);
      if (data.isEmpty) {
        if (fallback != null) return fallback;
        throw StateError('Empty property payload for $listingId');
      }
      final payload = Map<String, dynamic>.from(data)..['id'] = listingId;
      return PropertyListingDto.fromJson(payload);
    } catch (e) {
      debugPrint('ListingsRepository.confirmListing($listingId): $e');
      if (fallback != null) return fallback;
      rethrow;
    }
  }

  ({int? id, PropertyListing? listing}) _parseListingMutationResponse(
    dynamic rawData, {
    required int? fallbackId,
  }) {
    final data = _asResponseMap(rawData);
    final id = _parseId(data['id']) ?? fallbackId;
    PropertyListing? listing;
    if (id != null && data.isNotEmpty) {
      try {
        final payload = Map<String, dynamic>.from(data);
        payload['id'] = id;
        listing = PropertyListingDto.fromJson(payload);
      } catch (e) {
        debugPrint(
          'ListingsRepository._parseListingMutationResponse: could not parse listing: $e',
        );
      }
    }
    return (id: id, listing: listing);
  }

  /// The listing the server returns, directly (the contract has no `data`
  /// wrapper).
  Map<String, dynamic> _asResponseMap(dynamic rawData) =>
      rawData is Map ? Map<String, dynamic>.from(rawData) : const {};

  int? _parseId(dynamic raw) {
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim());
    return null;
  }

  /// Fetches a single page of the user's listings using cursor pagination.
  ///
  /// First page is **merged** with the durable owner cache so:
  /// - just-created pending listings never disappear if the server page lags
  /// - cold start still shows recently created rows when bootstrap is slow
  Future<({List<PropertyListing> items, String? nextCursor, bool hasMore})>
  fetchMyListingsPage({String? cursor, int limit = 20}) async {
    final queryParameters = <String, dynamic>{'limit': limit};
    if (cursor != null && cursor.isNotEmpty) {
      queryParameters['cursor'] = cursor;
    }

    try {
      final response = await _ref
          .watch(apiClientProvider)
          .get(
            FlatmatesEndpoints.myProperties,
            queryParameters: queryParameters,
          );
      final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
      final page = parsePagedEnvelope(
        data,
        PropertyListingDto.fromJson,
        label: 'myListings',
      );

      final isFirstPage = cursor == null || cursor.isEmpty;
      if (!isFirstPage) {
        return (
          items: page.items,
          nextCursor: page.nextCursor,
          hasMore: page.hasMore,
        );
      }

      // First page merge: keep cache-only rows when more pages exist.
      // When hasMore is false the first page is the full owner set, so prune
      // stale active cache-only rows (pending/rejected extras still kept).
      final merged = _mergeServerAndCache(
        page.items,
        _readListingsCache(),
        preserveAllCacheOnly: page.hasMore,
      );
      _writeListingsCache(merged);

      debugPrint(
        'ListingsRepository.fetchMyListingsPage: server=${page.items.length} '
        'merged=${merged.length}',
      );

      return (
        items: merged,
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
      );
    } catch (e, st) {
      debugPrint('ListingsRepository.fetchMyListingsPage network failed: $e');
      // Only serve cache for transient transport / server failures so auth
      // expiry and programming errors still propagate.
      if (_isTransientListingsFailure(e) &&
          (cursor == null || cursor.isEmpty)) {
        final cached = _readListingsCache();
        if (cached.isNotEmpty) {
          debugPrint(
            'ListingsRepository.fetchMyListingsPage: transient error, '
            'serving ${cached.length} cached listing(s)',
          );
          return (items: cached, nextCursor: null, hasMore: false);
        }
      }
      Error.throwWithStackTrace(e, st);
    }
  }

  static bool _isTransientListingsFailure(Object e) {
    if (e is NetworkFailure) return true;
    if (e is ServerFailure) return true;
    if (e is RateLimitFailure) return true;
    return false;
  }

  /// Every listing of the owner: follows `next_cursor` until the list ends.
  Future<List<PropertyListing>> fetchMyListings({int limit = 100}) async {
    final allItems = <PropertyListing>[];
    String? cursor;
    var pageIndex = 0;
    while (true) {
      final page = await fetchMyListingsPage(cursor: cursor, limit: limit);
      if (pageIndex == 0) {
        // First page already merged with cache.
        allItems.addAll(page.items);
      } else {
        // Later pages: append only new ids.
        for (final item in page.items) {
          if (!allItems.any((existing) => existing.id == item.id)) {
            allItems.add(item);
          }
        }
      }
      if (!page.hasMore ||
          page.nextCursor == null ||
          page.nextCursor!.isEmpty) {
        break;
      }
      cursor = page.nextCursor;
      pageIndex++;
    }
    if (allItems.isNotEmpty) {
      // Full reconciliation: server order is authoritative; drop orphans.
      _writeListingsCache(allItems);
    }
    return allItems;
  }

  /// Upserts a listing into the owner cache (used right after create), so a
  /// server page that lags behind the create does not drop it.
  Future<void> cacheOwnerListing(PropertyListing listing) async {
    if (listing.id <= 0) return;
    final next = _mergeServerAndCache(
      [listing],
      _readListingsCache(),
      preserveAllCacheOnly: true,
    );
    _writeListingsCache(next);
    debugPrint(
      'ListingsRepository.cacheOwnerListing: cached id=${listing.id} '
      'total=${next.length}',
    );
  }

  /// Server rows win on id collision.
  ///
  /// When [preserveAllCacheOnly] is true (partial first-page merges and
  /// create-time upserts), every cache-only row is kept so active listings
  /// omitted from page 1 are not pruned from disk. Callers that fully
  /// reconcile the owner set should write the complete list without this flag.
  List<PropertyListing> _mergeServerAndCache(
    List<PropertyListing> server,
    List<PropertyListing> cache, {
    bool preserveAllCacheOnly = false,
  }) {
    final serverIds = <int>{
      for (final item in server)
        if (item.id > 0) item.id,
    };
    final extras = <PropertyListing>[
      for (final item in cache)
        if (item.id > 0 &&
            !serverIds.contains(item.id) &&
            (preserveAllCacheOnly || item.isUnderReview || item.isRejected))
          item,
    ]..sort((a, b) => b.id.compareTo(a.id));
    // Pending creates first, then server order (API is newest-first).
    return [...extras, ...server];
  }

  /// Clears the owner cache (call on sign-out / account switch) and deletes
  /// any listing cache an earlier build left on disk.
  Future<void> clearOwnerListingsCache() async {
    _memoryCache.clear();
    try {
      final prefs = _ref.read(appPreferencesProvider);
      for (final key in prefs.keys.toList()) {
        if (key.startsWith(_legacyDiskKeyPrefix)) await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('ListingsRepository.clearOwnerListingsCache: $e');
    }
  }

  int? get _cacheUserId {
    try {
      final id = _ref.read(bootstrapControllerProvider).valueOrNull?.profile.id;
      if (id == null || id <= 0) return null;
      return id;
    } catch (e) {
      debugPrint('ListingsRepository._cacheUserId: $e');
      return null;
    }
  }

  /// The rows cached for the signed-in account, or none when the account is
  /// not known yet. Rows of any other account are dropped.
  List<PropertyListing> _readListingsCache() {
    final userId = _cacheUserId;
    if (userId == null) return const [];
    _memoryCache.removeWhere((owner, _) => owner != userId);
    return _memoryCache[userId] ?? const [];
  }

  void _writeListingsCache(List<PropertyListing> listings) {
    final userId = _cacheUserId;
    if (userId == null) return;
    _memoryCache
      ..clear()
      ..[userId] = listings
          .where((item) => item.id > 0)
          .toList(growable: false);
  }

  /// Pauses a live listing, or resumes a paused one: a PUT whose only key is
  /// `listing_preferences.moderation_status` is the owner toggle. [paused] is
  /// the current state (true sends `live`, false sends `paused`).
  ///
  /// The server accepts `live` only from `paused` with no review flag; any
  /// other state is a 409 `LISTING_STATUS_CONFLICT`. A toggle does not send the
  /// listing back to review (a content edit does).
  Future<void> togglePause(int listingId, {required bool paused}) async {
    final next = paused
        ? ListingModerationStatus.live
        : ListingModerationStatus.paused;
    await _ref
        .watch(apiClientProvider)
        .put(
          FlatmatesEndpoints.property(listingId),
          data: {
            'listing_preferences': {'moderation_status': next.wire},
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
