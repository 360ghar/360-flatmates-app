import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/bootstrap_controller.dart';
import '../../chats/application/cursor_list_controller.dart';
import '../../chats/chats_repository.dart';
import '../../location/application/location_controller.dart';
import '../discover_repository.dart';
import 'discover_feed_controller.dart';

class MapListingsState {
  const MapListingsState({
    this.listings = const [],
    this.isLoading = false,
    this.error,
    this.filters = const DiscoverFilters(),
  });

  final List<PropertyListing> listings;
  final bool isLoading;
  final Object? error;
  final DiscoverFilters filters;

  bool get hasError => error != null;
  bool get isEmpty => listings.isEmpty && !isLoading;

  MapListingsState copyWith({
    List<PropertyListing>? listings,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    DiscoverFilters? filters,
  }) {
    return MapListingsState(
      listings: listings ?? this.listings,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
    );
  }
}

class MapListingsController extends Notifier<MapListingsState> {
  static const double defaultLocationRadiusKm = 10.0;
  static const int _pageSize = 50;

  int _filterVersion = 0;
  bool _isLoadingActive = false;

  @override
  MapListingsState build() {
    final sharedFilters = ref.watch(discoverFiltersProvider);
    final initialFilters = sharedFilters != null
        ? const DiscoverFilters().copyWith(
            query: sharedFilters.query,
            location: sharedFilters.location,
            priceMin: sharedFilters.priceMin,
            priceMax: sharedFilters.priceMax,
            sharingType: sharedFilters.sharingType,
            genderPreference: sharedFilters.genderPreference,
            features: sharedFilters.features,
            bedrooms: sharedFilters.bedrooms,
            pets: sharedFilters.pets,
            smoking: sharedFilters.smoking,
            vibe: sharedFilters.vibe,
            moveInTimeline: sharedFilters.moveInTimeline,
            latitude: sharedFilters.latitude,
            longitude: sharedFilters.longitude,
            radiusKm: sharedFilters.radiusKm,
          )
        : const DiscoverFilters();
    Future.microtask(() => _autoInjectLocationThenLoad());
    return MapListingsState(filters: initialFilters, isLoading: true);
  }

  Future<void> _autoInjectLocationThenLoad() async {
    if (!state.filters.hasGeoLocation && !_hasTextLocation(state.filters)) {
      final selectedLocation = ref
          .read(locationControllerProvider)
          .selectedLocation;
      if (selectedLocation != null) {
        state = state.copyWith(
          filters: state.filters.copyWith(
            latitude: selectedLocation.latitude,
            longitude: selectedLocation.longitude,
            radiusKm: defaultLocationRadiusKm,
          ),
        );
      }
    }
    await load();
  }

  Future<void> load() async {
    if (_isLoadingActive) return;
    _isLoadingActive = true;
    state = state.copyWith(isLoading: true, clearError: true);

    final myVersion = _filterVersion;
    try {
      final profile = ref
          .read(bootstrapControllerProvider)
          .valueOrNull
          ?.profile;
      final repo = ref.read(discoverRepositoryProvider);
      final newListings = await repo.fetchListings(
        currentUser: profile,
        filters: state.filters,
        limit: _pageSize,
      );

      if (myVersion != _filterVersion) {
        // Stale result — filters changed during the request.
      } else {
        state = state.copyWith(listings: newListings, isLoading: false);
      }
    } catch (e) {
      debugPrint('MapListingsController.load failed: $e');
      if (myVersion == _filterVersion) {
        state = state.copyWith(isLoading: false, error: e);
      }
    } finally {
      _isLoadingActive = false;
    }

    if (myVersion != _filterVersion) {
      await load();
    }
  }

  Future<int?> setLiked(int propertyId, bool liked) async {
    final original = state.listings;
    final index = original.indexWhere((listing) => listing.id == propertyId);
    if (index >= 0) {
      final optimistic = [...original];
      optimistic[index] = optimistic[index].copyWith(liked: liked);
      state = state.copyWith(listings: optimistic);
    }

    try {
      final conversationId = await ref
          .read(discoverRepositoryProvider)
          .setLiked(propertyId, liked);
      ref.invalidate(conversationsProvider);
      // The ConversationsPage Chats tab watches the cursor controller, not the
      // legacy FutureProvider above — refresh it too or the tab stays stale
      // until a manual pull-to-refresh.
      ref.invalidate(conversationsListControllerProvider);

      // Keep the Liked tab in sync when a property is liked from the map.
      if (index >= 0) {
        final listing = state.listings[index];
        final outgoing = ref.read(outgoingLikesListControllerProvider.notifier);
        if (liked) {
          outgoing.upsertOutgoingLike(
            OutgoingLikeModel.fromPropertyListing(listing),
          );
        } else {
          outgoing.removeOptimistically(
            OutgoingLikeModel.fromPropertyListing(listing),
          );
        }
      }
      // Keep the discover feed heart in sync without a full reload.
      ref
          .read(discoverFeedControllerProvider.notifier)
          .applyLikedLocally(propertyId, liked);
      return conversationId;
    } catch (e) {
      debugPrint('MapListingsController.setLiked failed: $e');
      state = state.copyWith(listings: original);
      rethrow;
    }
  }

  /// Toggles like for [propertyId] (like ↔ unlike). Returns conversation id
  /// when a like creates/reuses a conversation.
  Future<int?> toggleLike(int propertyId) async {
    final index = state.listings.indexWhere(
      (listing) => listing.id == propertyId,
    );
    if (index < 0) return null;
    final currentLiked = state.listings[index].liked ?? false;
    return setLiked(propertyId, !currentLiked);
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
    state = state.copyWith(
      listings: const [],
      isLoading: true,
      clearError: true,
      filters: state.filters.copyWith(
        latitude: latitude,
        longitude: longitude,
        radiusKm: normalizedRadiusKm,
        clearLocation: true,
      ),
    );
    _filterVersion++;
    unawaited(load());
  }

  void updateTextLocationFilter({required String location}) {
    final normalizedLocation = location.trim();
    if (normalizedLocation.isEmpty) return;
    state = state.copyWith(
      listings: const [],
      isLoading: true,
      clearError: true,
      filters: state.filters.copyWith(
        location: normalizedLocation,
        clearLatitude: true,
        clearLongitude: true,
        clearRadiusKm: true,
      ),
    );
    _filterVersion++;
    unawaited(load());
  }

  void clearLocationFilter() {
    state = state.copyWith(
      listings: const [],
      isLoading: true,
      clearError: true,
      filters: state.filters.copyWith(
        clearLocation: true,
        clearLatitude: true,
        clearLongitude: true,
        clearRadiusKm: true,
      ),
    );
    _filterVersion++;
    unawaited(load());
  }

  bool _hasTextLocation(DiscoverFilters filters) {
    return filters.location?.trim().isNotEmpty ?? false;
  }
}

final mapListingsProvider =
    NotifierProvider<MapListingsController, MapListingsState>(
      MapListingsController.new,
    );

final filteredMapListingsProvider = Provider<List<PropertyListing>>((ref) {
  final mapState = ref.watch(mapListingsProvider);
  final profile = ref.watch(
    bootstrapControllerProvider.select((s) => s.valueOrNull?.profile),
  );
  return applyDiscoverListingFilters(
    items: mapState.listings,
    filters: mapState.filters,
    currentUserId: profile?.id,
    profile: profile,
  );
});
