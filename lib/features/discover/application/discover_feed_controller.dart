import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/bootstrap_controller.dart';
import '../discover_repository.dart';
import 'move_in_filter.dart';

class DiscoverFeedState {
  const DiscoverFeedState({
    this.listings = const [],
    this.fetchedCount = 0,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.filters = const DiscoverFilters(),
  });

  final List<PropertyListing> listings;
  final int fetchedCount;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final DiscoverFilters filters;

  bool get hasError => error != null;
  bool get isEmpty => listings.isEmpty && !isLoading;

  DiscoverFeedState copyWith({
    List<PropertyListing>? listings,
    int? fetchedCount,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
    DiscoverFilters? filters,
  }) {
    return DiscoverFeedState(
      listings: listings ?? this.listings,
      fetchedCount: fetchedCount ?? this.fetchedCount,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
    );
  }
}

class DiscoverFeedController extends Notifier<DiscoverFeedState> {
  static const double defaultLocationRadiusKm = 10.0;
  static const int _pageSize = 20;

  // Monotonic version bumped each time filters change. A load that
  // observes a different version after its `await` is stale and
  // discards its result.
  int _filterVersion = 0;
  bool _isLoadingActive = false;

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
      final offset = clearAll ? 0 : state.fetchedCount;
      final newListings = await repo.fetchListings(
        currentUser: profile,
        filters: state.filters,
        offset: offset,
      );

      if (myVersion != _filterVersion) {
        // Stale result — filters changed during the request.
        // Skip applying it; the trailing reload below will re-fetch.
      } else {
        state = state.copyWith(
          listings: clearAll
              ? newListings
              : [...state.listings, ...newListings],
          fetchedCount: clearAll
              ? newListings.length
              : state.fetchedCount + newListings.length,
          isLoading: false,
          isLoadingMore: false,
          hasMore: newListings.length >= _pageSize,
        );
      }
    } catch (e) {
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

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    await load(clearAll: false);
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);
    try {
      final profile = ref
          .read(bootstrapControllerProvider)
          .valueOrNull
          ?.profile;
      final repo = ref.read(discoverRepositoryProvider);
      final listings = await repo.fetchListings(
        currentUser: profile,
        filters: state.filters,
      );
      state = state.copyWith(
        listings: listings,
        fetchedCount: listings.length,
        isRefreshing: false,
        hasMore: listings.length >= _pageSize,
      );
    } catch (e) {
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
      ),
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

  void _setFilters(DiscoverFilters filters) {
    state = state.copyWith(filters: filters);
    ref.read(discoverFiltersProvider.notifier).state = filters.isEmpty
        ? null
        : filters;
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
      final query = filters.query?.trim().toLowerCase() ?? '';

      if (filters.isEmpty && query.isEmpty) {
        return items.where((item) => item.ownerId != profile?.id).toList();
      }

      return items.where((item) {
        if (item.ownerId == profile?.id) return false;

        final matchesBedrooms =
            filters.bedrooms == null || item.bedrooms == filters.bedrooms;

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
            matchesFeature &&
            matchesQuery &&
            matchesVibe &&
            matchesMoveIn;
      }).toList();
    });

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
