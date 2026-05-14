import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/google_places_service.dart';
import '../../../core/location/nominatim_service.dart';
import '../../../core/location/place_suggestion.dart';

final locationSearchProvider =
    NotifierProvider<LocationSearchNotifier, LocationSearchState>(
      LocationSearchNotifier.new,
    );

class LocationSearchState {
  final List<PlaceSuggestion> suggestions;
  final bool isLoading;

  const LocationSearchState({
    this.suggestions = const [],
    this.isLoading = false,
  });

  LocationSearchState copyWith({
    List<PlaceSuggestion>? suggestions,
    bool? isLoading,
  }) {
    return LocationSearchState(
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LocationSearchNotifier extends Notifier<LocationSearchState> {
  Timer? _debounce;

  @override
  LocationSearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const LocationSearchState();
  }

  void onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      state = const LocationSearchState();
      return;
    }
    state = state.copyWith(isLoading: true);
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search(query.trim());
    });
  }

  Future<void> _search(String query) async {
    final googleService = ref.read(googlePlacesServiceProvider);
    final nominatimService = ref.read(nominatimServiceProvider);

    // Try Google Places first
    var results = await googleService.getPlaceSuggestions(query);

    // If Google returned nothing (empty key, REQUEST_DENIED, etc.),
    // fall back to Nominatim/OpenStreetMap.
    if (results.isEmpty) {
      results = await nominatimService.search(query);
    }

    state = LocationSearchState(suggestions: results, isLoading: false);
  }

  Future<PlaceDetails?> resolveSuggestion(PlaceSuggestion suggestion) {
    switch (suggestion.source) {
      case PlaceSuggestionSource.googlePlaces:
        return ref
            .read(googlePlacesServiceProvider)
            .getPlaceDetails(
              suggestion.placeId,
              preferredName: suggestion.mainText,
            );
      case PlaceSuggestionSource.nominatim:
        return ref.read(nominatimServiceProvider).getDetails(suggestion);
    }
  }

  void clear() {
    _debounce?.cancel();
    state = const LocationSearchState();
  }
}
