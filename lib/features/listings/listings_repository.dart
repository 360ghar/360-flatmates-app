import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/endpoints.dart';
import '../../core/errors/app_failure.dart';
import '../../core/providers.dart';
import '../../core/utils/paged_envelope.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../discover/data/property_listing_dto.dart';
import '../discover/discover_repository.dart';
import '../discover/domain/property_listing.dart';

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

  /// Street / full address collected in the form. Prefer over composed location.
  final String? fullAddress;
  final int? floorNumber;
  final int? totalFloors;

  /// Preferred roommate age range and hard filters — stored under
  /// [listing_preferences] (backend `ListingPreferences` allows extra keys).
  final int? ageMin;
  final int? ageMax;
  final List<String> nonNegotiables;
  final String? electricityIncluded;
  final double? electricityEst;
  final double? cookCost;
  final double? maidCost;
  final double? setupCost;

  Map<String, dynamic> toJson() {
    final composedAddress = [
      if (subLocality != null && subLocality!.trim().isNotEmpty)
        subLocality!.trim(),
      if (locality != null && locality!.trim().isNotEmpty) locality!.trim(),
      if (city != null && city!.trim().isNotEmpty) city!.trim(),
    ].join(', ');
    final street = fullAddress?.trim();
    final resolvedAddress = (street != null && street.isNotEmpty)
        ? street
        : composedAddress;

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
    if (ageMin != null) {
      preferences['preferred_age_min'] = ageMin;
    }
    if (ageMax != null) {
      preferences['preferred_age_max'] = ageMax;
    }
    if (nonNegotiables.isNotEmpty) {
      preferences['non_negotiables'] = nonNegotiables;
    }
    if (electricityIncluded != null && electricityIncluded!.isNotEmpty) {
      preferences['electricity_included'] = electricityIncluded;
    }
    if (electricityEst != null) {
      preferences['electricity_est'] = electricityEst;
    }
    if (cookCost != null) {
      preferences['cook_cost'] = cookCost;
    }
    if (maidCost != null) {
      preferences['maid_cost'] = maidCost;
    }
    if (setupCost != null) {
      preferences['setup_cost'] = setupCost;
    }
    // Keep street address in preferences too so edit restore can rehydrate
    // the form field without losing the top-level Property.full_address.
    if (street != null && street.isNotEmpty) {
      preferences['full_address'] = street;
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
      'full_address': resolvedAddress.isEmpty ? null : resolvedAddress,
      'area_sqft': areaSqft,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'floor_number': floorNumber,
      'total_floors': totalFloors,
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
  ListingsRepository(this._ref);

  final Ref _ref;

  /// Serializes durable cache read/merge/write so a first-page fetch cannot
  /// finish after [cacheOwnerListing] and clobber a newly seeded row.
  Future<void> _cacheChain = Future<void>.value();

  /// Disk key always written so cold start works even before bootstrap resolves.
  static const _latestCacheKey = 'my_listings_cache_latest_v1';

  Future<T> _withCacheLock<T>(Future<T> Function() action) {
    final done = Completer<T>();
    _cacheChain = _cacheChain.catchError((Object _) {}).then((_) async {
      try {
        done.complete(await action());
      } catch (e, st) {
        done.completeError(e, st);
      }
    });
    return done.future;
  }

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
    final body = Map<String, dynamic>.from(request.toJson())
      ..removeWhere((_, value) => value == null);
    final response = await _ref
        .watch(apiClientProvider)
        .put(FlatmatesEndpoints.property(listingId), data: body);
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

  Map<String, dynamic> _asResponseMap(dynamic rawData) {
    if (rawData is! Map) return const {};
    final root = Map<String, dynamic>.from(rawData);
    final nested = root['data'];
    if (nested is Map && root['id'] == null) {
      return Map<String, dynamic>.from(nested);
    }
    return root;
  }

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

      // First page is partial — non-destructive upsert into disk cache.
      final merged = await _withCacheLock(() async {
        final cached = _readListingsCache();
        final next = _mergeServerAndCache(
          page.items,
          cached,
          preserveAllCacheOnly: true,
        );
        await _writeListingsCache(next);
        return next;
      });

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

  /// Backwards-compatible helper aggregating all pages into a single list.
  Future<List<PropertyListing>> fetchMyListings({int limit = 20}) async {
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
      await _withCacheLock(() => _writeListingsCache(allItems));
    }
    return allItems;
  }

  /// Upserts a listing into the durable owner cache (used right after create).
  ///
  /// **Must be awaited** before list refresh so a concurrent empty server page
  /// cannot race past an unfinished write.
  Future<void> cacheOwnerListing(PropertyListing listing) async {
    if (listing.id <= 0) return;
    await _withCacheLock(() async {
      final existing = _readListingsCache();
      final next = _mergeServerAndCache(
        [listing],
        existing,
        preserveAllCacheOnly: true,
      );
      await _writeListingsCache(next);
      debugPrint(
        'ListingsRepository.cacheOwnerListing: cached id=${listing.id} '
        'total=${next.length}',
      );
    });
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

  /// Clears durable owner-listing cache (call on sign-out / account switch).
  Future<void> clearOwnerListingsCache() async {
    try {
      final prefs = _ref.read(appPreferencesProvider);
      // Wipe latest + any user-scoped keys still known from bootstrap.
      for (final key in _cacheKeys()) {
        await prefs.remove(key);
      }
      // Bootstrap may already be gone at sign-out; still wipe the latest key.
      await prefs.remove(_latestCacheKey);
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

  List<String> _cacheKeys() {
    final keys = <String>[_latestCacheKey];
    final userId = _cacheUserId;
    if (userId != null) {
      keys.add('my_listings_cache_v1_$userId');
    }
    return keys;
  }

  List<PropertyListing> _readListingsCache() {
    try {
      final prefs = _ref.read(appPreferencesProvider);
      // Prefer user-scoped key, then latest (covers cold start before bootstrap).
      final userId = _cacheUserId;
      final orderedKeys = <String>[
        if (userId != null && userId > 0) 'my_listings_cache_v1_$userId',
        _latestCacheKey,
      ];
      for (final key in orderedKeys) {
        final raw = prefs.getString(key);
        if (raw == null || raw.isEmpty) continue;
        try {
          final decoded = jsonDecode(raw);
          if (decoded is! List) continue;
          final items = PropertyListingDto.fromJsonList(decoded);
          if (items.isNotEmpty) return items;
        } catch (e) {
          debugPrint('ListingsRepository._readListingsCache($key): $e');
        }
      }
    } catch (e) {
      // Tests / early bootstrap without AppPreferences override.
      debugPrint('ListingsRepository._readListingsCache unavailable: $e');
    }
    return const [];
  }

  Future<void> _writeListingsCache(List<PropertyListing> listings) async {
    try {
      final prefs = _ref.read(appPreferencesProvider);
      final payload = listings
          .where((item) => item.id > 0)
          .map(PropertyListingDto.toCacheJson)
          .toList(growable: false);
      final encoded = jsonEncode(payload);
      for (final key in _cacheKeys()) {
        await prefs.setString(key, encoded);
      }
    } catch (e) {
      debugPrint('ListingsRepository._writeListingsCache: $e');
    }
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
