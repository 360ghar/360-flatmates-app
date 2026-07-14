import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/bootstrap_controller.dart';
import '../../chats/application/cursor_list_controller.dart';
import '../../chats/chats_repository.dart';
import '../discover_repository.dart';
import 'move_in_filter.dart';

class DiscoverFeedState {
  const DiscoverFeedState({
    this.listings = const [],
    this.nextCursor,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.filters = const DiscoverFilters(),
    this.isBroadened = false,
  });

  final List<PropertyListing> listings;
  final String? nextCursor;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final DiscoverFilters filters;

  /// True when the current page was fetched with a broader radius (or no geo
  /// filter) than the user's selected location because the user's radius
  /// returned zero listings. The UI shows a "showing listings beyond your
  /// area" hint when this is true.
  final bool isBroadened;

  bool get hasError => error != null;
  bool get isEmpty => listings.isEmpty && !isLoading;

  DiscoverFeedState copyWith({
    List<PropertyListing>? listings,
    String? nextCursor,
    bool setNextCursorNull = false,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
    DiscoverFilters? filters,
    bool? isBroadened,
  }) {
    return DiscoverFeedState(
      listings: listings ?? this.listings,
      nextCursor: setNextCursorNull ? null : (nextCursor ?? this.nextCursor),
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
      isBroadened: isBroadened ?? this.isBroadened,
    );
  }
}

class DiscoverFeedController extends Notifier<DiscoverFeedState> {
  static const double defaultLocationRadiusKm = 10.0;

  /// When an initial geo-filtered load returns zero listings, the controller
  /// retries with progressively broader radii from this ladder before finally
  /// falling back to no geo filter. This keeps the feed useful for users who
  /// are not physically near any available listing.
  static const List<double> _broadenRadiusLadder = [50.0, 100.0];

  // Monotonic version bumped each time filters change. A load that
  // observes a different version after its `await` is stale and
  // discards its result.
  int _filterVersion = 0;
  bool _isLoadingActive = false;

  /// Filters actually used for the last successful first-page fetch when
  /// radius was broadened (or geo dropped). Pagination must reuse these so
  /// the cursor stays coherent with the page that produced it.
  DiscoverFilters? _activeFetchFilters;

  @override
  DiscoverFeedState build() {
    final initialFilters =
        ref.read(discoverFiltersProvider) ?? const DiscoverFilters();
    Future.microtask(() {
      if (state.isLoading) load();
    });
    return DiscoverFeedState(isLoading: true, filters: initialFilters);
  }

  Future<void> load({bool clearAll = true}) async {
    if (_isLoadingActive) {
      // A load is in flight. Mark the filter version as dirty by bumping
      // it; the in-flight load will observe the mismatch and reload.
      if (clearAll) {
        _filterVersion++;
        _activeFetchFilters = null;
        state = state.copyWith(
          isLoading: true,
          isLoadingMore: false,
          clearError: true,
        );
      }
      return;
    }
    _isLoadingActive = true;
    if (clearAll) {
      // Fresh load starts from the user's selected filters; any prior
      // broaden-session filters are invalid for the new first page.
      _activeFetchFilters = null;
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(isLoadingMore: true, clearError: true);
    }

    final myVersion = _filterVersion;
    try {
      final profile = ref
          .read(bootstrapControllerProvider)
          .valueOrNull
          ?.profile;
      final repo = ref.read(discoverRepositoryProvider);
      final cursor = clearAll ? null : state.nextCursor;
      // Pagination must reuse the filters that produced the cursor (which may
      // be broadened). First-page loads always use the user's filters.
      final fetchFilters = clearAll
          ? state.filters
          : (_activeFetchFilters ?? state.filters);
      var page = await repo.fetchListingsPage(
        currentUser: profile,
        filters: fetchFilters,
        cursor: cursor,
      );
      var newListings = page.items;
      var broadened = false;
      DiscoverFilters? effectiveFilters;

      // Only broaden on a fresh, geo-filtered load that returned nothing.
      // Store the effective filters so load-more reuses the same radius/geo.
      if (clearAll &&
          cursor == null &&
          newListings.isEmpty &&
          state.filters.hasGeoLocation &&
          myVersion == _filterVersion) {
        final broadenedResult = await _broadenAndFetch(
          profile: profile,
          repo: repo,
          baseFilters: state.filters,
          myVersion: myVersion,
        );
        if (broadenedResult != null) {
          page = (
            items: broadenedResult.items,
            rawCount: broadenedResult.rawCount,
            nextCursor: broadenedResult.nextCursor,
          );
          newListings = page.items;
          broadened = true;
          effectiveFilters = broadenedResult.filters;
        }
      }

      if (myVersion != _filterVersion) {
        // Stale result — filters changed during the request.
        // Skip applying it; the trailing reload below will re-fetch.
      } else {
        if (clearAll) {
          _activeFetchFilters = effectiveFilters;
        }
        state = state.copyWith(
          listings: clearAll
              ? newListings
              : [...state.listings, ...newListings],
          nextCursor: page.nextCursor,
          isLoading: false,
          isLoadingMore: false,
          hasMore: page.nextCursor != null,
          isBroadened: clearAll ? broadened : null,
        );
      }
    } catch (e) {
      debugPrint('DiscoverFeedController.load failed: $e');
      if (myVersion == _filterVersion) {
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: e,
        );
      }
      // If the version changed, the trailing reload will replace this error.
    } finally {
      _isLoadingActive = false;
    }

    if (myVersion != _filterVersion) {
      await load();
    }
  }

  /// Retries the first-page fetch with progressively broader radii (then no
  /// geo filter) until a non-empty page is found. Returns `null` if every
  /// attempt also returned zero listings (so the caller keeps the original
  /// empty result). Aborts early if the filter version changes mid-flight.
  ///
  /// On success, [filters] is the effective filter set used for that page
  /// (must be reused for subsequent cursor pagination).
  Future<
    ({
      List<PropertyListing> items,
      int rawCount,
      String? nextCursor,
      DiscoverFilters filters,
    })?
  >
  _broadenAndFetch({
    required FlatmatesProfileModel? profile,
    required DiscoverRepository repo,
    required DiscoverFilters baseFilters,
    required int myVersion,
  }) async {
    for (final radius in _broadenRadiusLadder) {
      if (myVersion != _filterVersion) return null;
      final filters = baseFilters.copyWith(radiusKm: radius);
      final page = await repo.fetchListingsPage(
        currentUser: profile,
        filters: filters,
      );
      if (page.items.isNotEmpty) {
        return (
          items: page.items,
          rawCount: page.rawCount,
          nextCursor: page.nextCursor,
          filters: filters,
        );
      }
    }
    // Final fallback: drop the geo filter entirely.
    if (myVersion != _filterVersion) return null;
    final noGeoFilters = baseFilters.copyWith(
      clearLatitude: true,
      clearLongitude: true,
      clearRadiusKm: true,
    );
    final page = await repo.fetchListingsPage(
      currentUser: profile,
      filters: noGeoFilters,
    );
    if (page.items.isEmpty) return null;
    return (
      items: page.items,
      rawCount: page.rawCount,
      nextCursor: page.nextCursor,
      filters: noGeoFilters,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    await load(clearAll: false);
  }

  /// Updates the local liked flag for [id] without a network call.
  ///
  /// Used by map (and similar) surfaces that already persisted the like so
  /// the feed heart stays in parity without a full reload.
  void applyLikedLocally(int id, bool liked) {
    final index = state.listings.indexWhere((listing) => listing.id == id);
    if (index < 0) return;
    final listings = [...state.listings];
    listings[index] = listings[index].copyWith(liked: liked);
    state = state.copyWith(listings: listings);
  }

  /// Optimistically toggles the liked state of a listing in the feed.
  ///
  /// The card fills/unfills instantly; on network failure the previous
  /// list is restored. Returns the `conversation_id` (non-null when a
  /// like created/reused a conversation).
  ///
  /// [property] can be supplied when the listing is not currently in the
  /// feed state (e.g. the Liked tab) so the outgoing-likes list can still be
  /// updated optimistically.
  Future<int?> toggleLike(int propertyId, {PropertyListing? property}) async {
    final original = state.listings;
    final index = original.indexWhere((listing) => listing.id == propertyId);
    final item = index >= 0 ? original[index] : property;
    if (item == null) return null;

    final currentLiked = item.liked ?? false;
    final newLiked = !currentLiked;
    final optimistic = [...original];
    if (index >= 0) {
      optimistic[index] = item.copyWith(liked: newLiked);
      state = state.copyWith(listings: optimistic);
    }

    try {
      final conversationId = await ref
          .read(discoverRepositoryProvider)
          .setLiked(propertyId, newLiked);
      // Invalidate on both like and unlike so the conversation list stays
      // in sync (unliking may remove a pending conversation/like entry).
      ref.invalidate(conversationsProvider);
      // The ConversationsPage Chats tab watches the cursor controller, not the
      // legacy FutureProvider above — refresh it too or the tab stays stale
      // until a manual pull-to-refresh.
      ref.invalidate(conversationsListControllerProvider);

      // Keep the Liked tab in sync optimistically (no full refresh — avoids
      // flicker + extra network). Map's setLiked path is aligned.
      final outgoing = ref.read(outgoingLikesListControllerProvider.notifier);
      if (newLiked) {
        outgoing.upsertOutgoingLike(
          OutgoingLikeModel.fromPropertyListing(item.copyWith(liked: true)),
        );
      } else {
        outgoing.removeOptimistically(
          OutgoingLikeModel.fromPropertyListing(item),
        );
      }
      return conversationId;
    } catch (e) {
      debugPrint('DiscoverFeedController.toggleLike failed: $e');
      // Roll back the optimistic change on failure.
      if (index >= 0) {
        state = state.copyWith(listings: original);
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    // Bump the version so any in-flight load() observes the mismatch and
    // discards its (now stale) result instead of racing this refresh and
    // appending duplicate / out-of-order pages.
    _filterVersion++;
    _activeFetchFilters = null;
    state = state.copyWith(isRefreshing: true, clearError: true);
    try {
      final profile = ref
          .read(bootstrapControllerProvider)
          .valueOrNull
          ?.profile;
      final repo = ref.read(discoverRepositoryProvider);
      final myVersion = _filterVersion;
      var page = await repo.fetchListingsPage(
        currentUser: profile,
        filters: state.filters,
      );
      var broadened = false;
      DiscoverFilters? effectiveFilters;
      if (page.items.isEmpty &&
          state.filters.hasGeoLocation &&
          myVersion == _filterVersion) {
        final broadenedResult = await _broadenAndFetch(
          profile: profile,
          repo: repo,
          baseFilters: state.filters,
          myVersion: myVersion,
        );
        if (broadenedResult != null) {
          page = (
            items: broadenedResult.items,
            rawCount: broadenedResult.rawCount,
            nextCursor: broadenedResult.nextCursor,
          );
          broadened = true;
          effectiveFilters = broadenedResult.filters;
        }
      }
      // A filter change during the refresh wins: discard this result and let
      // the filter-driven load() repopulate the feed. Clear the refreshing
      // flag so the UI doesn't stay stuck in the loading state.
      if (myVersion != _filterVersion) {
        state = state.copyWith(isRefreshing: false);
        return;
      }
      _activeFetchFilters = effectiveFilters;
      state = state.copyWith(
        listings: page.items,
        nextCursor: page.nextCursor,
        isRefreshing: false,
        hasMore: page.nextCursor != null,
        isBroadened: broadened,
      );
    } catch (e) {
      debugPrint('DiscoverFeedController.refresh failed: $e');
      state = state.copyWith(isRefreshing: false, error: e);
    }
  }

  void updateFilters(DiscoverFilters filters) {
    _setFilters(_mergePersistentLocation(filters));
    load();
  }

  void updateLocationFilter({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) {
    if (!latitude.isFinite || !longitude.isFinite) return;

    final normalizedRadiusKm = radiusKm.isFinite && radiusKm > 0
        ? radiusKm
        : defaultLocationRadiusKm;

    _setFilters(
      state.filters.copyWith(
        latitude: latitude,
        longitude: longitude,
        radiusKm: normalizedRadiusKm,
        clearLocation: true,
      ),
      restartListings: true,
    );
    load();
  }

  void updateTextLocationFilter({required String location}) {
    final normalizedLocation = location.trim();
    if (normalizedLocation.isEmpty) return;

    _setFilters(
      state.filters.copyWith(
        location: normalizedLocation,
        clearLatitude: true,
        clearLongitude: true,
        clearRadiusKm: true,
      ),
      restartListings: true,
    );
    load();
  }

  void updateSearchQuery(String? query) {
    _setFilters(
      state.filters.copyWith(query: query, clearQuery: query == null),
    );
    load();
  }

  void updateBedrooms(int? bedrooms) {
    _setFilters(
      state.filters.copyWith(
        bedrooms: bedrooms,
        clearBedrooms: bedrooms == null,
      ),
    );
    load();
  }

  void updateFeature(String? featureKey) {
    if (featureKey == null) {
      _setFilters(state.filters.copyWith(features: []));
    } else {
      _setFilters(state.filters.copyWith(features: [featureKey]));
    }
    load();
  }

  void updateVibe(String? vibe) {
    _setFilters(state.filters.copyWith(vibe: vibe, clearVibe: vibe == null));
    load();
  }

  void updateMoveInTimeline(String? moveInTimeline) {
    _setFilters(
      state.filters.copyWith(
        moveInTimeline: moveInTimeline,
        clearMoveInTimeline: moveInTimeline == null,
      ),
    );
    load();
  }

  void clearFilters() {
    _setFilters(_locationOnlyFilters(state.filters));
    load();
  }

  DiscoverFilters _mergePersistentLocation(DiscoverFilters filters) {
    if (filters.hasGeoLocation || _hasTextLocation(filters)) return filters;
    return _locationOnlyFilters(state.filters).copyWith(
      query: filters.query,
      priceMin: filters.priceMin,
      priceMax: filters.priceMax,
      sharingType: filters.sharingType,
      genderPreference: filters.genderPreference,
      features: filters.features,
      bedrooms: filters.bedrooms,
      pets: filters.pets,
      smoking: filters.smoking,
      vibe: filters.vibe,
      moveInTimeline: filters.moveInTimeline,
    );
  }

  DiscoverFilters _locationOnlyFilters(DiscoverFilters filters) {
    if (filters.hasGeoLocation) {
      return DiscoverFilters(
        latitude: filters.latitude,
        longitude: filters.longitude,
        radiusKm: filters.radiusKm,
      );
    }
    if (_hasTextLocation(filters)) {
      return DiscoverFilters(location: filters.location);
    }
    return const DiscoverFilters();
  }

  bool _hasTextLocation(DiscoverFilters filters) {
    return filters.location?.trim().isNotEmpty ?? false;
  }

  void _setFilters(DiscoverFilters filters, {bool restartListings = false}) {
    _filterVersion++;
    // User-selected filters changed — discard any broaden-session filters so
    // the next first-page load starts from the new selection, not a stale
    // broadened radius / no-geo fallback.
    _activeFetchFilters = null;
    state = state.copyWith(
      listings: restartListings ? const [] : null,
      setNextCursorNull: restartListings,
      isLoading: restartListings ? true : null,
      isRefreshing: restartListings ? false : null,
      isLoadingMore: restartListings ? false : null,
      hasMore: restartListings ? true : null,
      clearError: restartListings,
      filters: filters,
      isBroadened: false,
    );
    ref
        .read(discoverFiltersProvider.notifier)
        .set(filters.isEmpty ? null : filters);
  }
}

final discoverFeedControllerProvider =
    NotifierProvider<DiscoverFeedController, DiscoverFeedState>(
      DiscoverFeedController.new,
    );

final bedroomOptionsProvider = Provider<List<int>>((ref) {
  final listings = ref.watch(
    discoverFeedControllerProvider.select((s) => s.listings),
  );
  return listings.map((item) => item.bedrooms).whereType<int>().toSet().toList()
    ..sort();
});

final featureOptionsProvider = Provider<List<String>>((ref) {
  final listings = ref.watch(
    discoverFeedControllerProvider.select((s) => s.listings),
  );
  return listings
      .expand((item) => item.features)
      .where((feature) => feature.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
});

final filteredListingsProvider = Provider<List<PropertyListing>>((ref) {
  final feedState = ref.watch(
    discoverFeedControllerProvider.select((s) => (s.listings, s.filters)),
  );
  final items = feedState.$1;
  final filters = feedState.$2;
  final profile = ref.watch(
    bootstrapControllerProvider.select((s) => s.valueOrNull?.profile),
  );
  return applyDiscoverListingFilters(
    items: items,
    filters: filters,
    currentUserId: profile?.id,
    profile: profile,
  );
});

List<PropertyListing> applyDiscoverListingFilters({
  required List<PropertyListing> items,
  required DiscoverFilters filters,
  required int? currentUserId,
  dynamic profile,
}) {
  final query = filters.query?.trim().toLowerCase() ?? '';

  if (filters.isEmpty && query.isEmpty) {
    return items.where((item) => item.ownerId != currentUserId).toList();
  }

  return items.where((item) {
    if (item.ownerId == currentUserId) return false;

    final matchesBedrooms =
        filters.bedrooms == null || item.bedrooms == filters.bedrooms;

    final smokingValue =
        (item.preferences?['smoking_drinking'] as String? ?? '').trim();
    final petsValue = (item.preferences?['pets'] as String? ?? '').trim();
    final hasPets =
        item.preferences?['has_pets'] == true ||
        item.preferences?['pets'] == true ||
        petsValue == 'have_pets' ||
        petsValue == 'pet_friendly';

    final matchesPets = switch (filters.pets) {
      null || 'no_preference' => true,
      'yes' => hasPets,
      'no' => !hasPets,
      _ => true,
    };

    final matchesSmoking = switch (filters.smoking) {
      null || 'no_preference' => true,
      'yes' => smokingValue == 'smoke_outside' || smokingValue == 'both_fine',
      'no' =>
        smokingValue.isEmpty ||
            smokingValue == 'neither' ||
            smokingValue == 'drink_occasionally',
      _ => true,
    };

    final matchesFeature =
        filters.features.isEmpty ||
        filters.features.every((fKey) => item.features.contains(fKey));

    final searchable = [
      item.title,
      item.locality,
      item.subLocality,
      item.city,
      item.description,
      item.ownerName,
      ...item.tags,
      ...item.features,
    ].whereType<String>().join(' ').toLowerCase();

    final matchesQuery = query.isEmpty || searchable.contains(query);

    final matchesVibe = _matchesVibe(filters.vibe, item, profile);
    final matchesMoveIn = listingMatchesMoveInFilter(
      item.availableFrom,
      filters.moveInTimeline,
    );

    return matchesBedrooms &&
        matchesPets &&
        matchesSmoking &&
        matchesFeature &&
        matchesQuery &&
        matchesVibe &&
        matchesMoveIn;
  }).toList();
}

bool _matchesVibe(String? vibe, PropertyListing listing, dynamic profile) {
  if (vibe == null) return true;

  final prefs = listing.preferences ?? const {};
  final smoking = prefs['smoking_drinking'] as String? ?? '';
  final guests = prefs['guests_policy'] as String? ?? '';
  final parties = prefs['parties_at_home'] as String? ?? '';
  final workStyle = prefs['work_style'] as String? ?? '';
  final pets = prefs['pets'] as String? ?? '';

  switch (vibe) {
    case 'quiet':
      return smoking == 'neither' &&
          (parties == 'never' || parties.isEmpty) &&
          (guests == 'no_overnight_guests' ||
              guests == 'occasional_ok' ||
              guests.isEmpty);
    case 'social':
      return (parties == 'occasional_weekends' ||
              parties == 'party_friendly') ||
          guests == 'open_house';
    case 'professional':
      return workStyle != 'wfh' && (smoking == 'neither' || smoking.isEmpty);
    case 'student':
      return true;
    case 'pet':
      return pets == 'have_pets' || pets == 'pet_friendly';
    default:
      return true;
  }
}
