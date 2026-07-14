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
  int _searchVersion = 0;

  @override
  LocationSearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const LocationSearchState();
  }

  void onSearchChanged(String query) {
    _debounce?.cancel();
    // Bump version on every keystroke so in-flight results for a previous
    // query cannot overwrite suggestions after the user keeps typing.
    _searchVersion++;
    if (query.trim().length < 2) {
      state = const LocationSearchState();
      return;
    }
    state = state.copyWith(isLoading: true);
    final versionAtSchedule = _searchVersion;
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Capture the scheduled query version so a late timer for an older
      // keystroke is ignored after a newer onSearchChanged.
      if (versionAtSchedule != _searchVersion) return;
      _search(query.trim());
    });
  }

  Future<void> _search(String query) async {
    // Use the current version (already bumped in onSearchChanged). Do not
    // bump again here — that would race with concurrent keystrokes.
    final version = _searchVersion;
    final googleService = ref.read(googlePlacesServiceProvider);
    final nominatimService = ref.read(nominatimServiceProvider);

    // Prefer Google Places when configured. Public Nominatim has a strict
    // 1 req/s usage policy and must not be hit in parallel on every keystroke
    // in production. Use Nominatim only when Places is unavailable.
    final List<PlaceSuggestion> google;
    final List<PlaceSuggestion> nominatim;
    if (GooglePlacesService.isConfigured) {
      google = await googleService
          .getPlaceSuggestions(query)
          .catchError((_) => <PlaceSuggestion>[]);
      nominatim = const [];
    } else {
      final results = await Future.wait([
        googleService
            .getPlaceSuggestions(query)
            .catchError((_) => <PlaceSuggestion>[]),
        nominatimService.search(query).catchError((_) => <PlaceSuggestion>[]),
      ]);
      google = results[0];
      nominatim = results[1];
    }

    if (version != _searchVersion) return;

    final merged = <PlaceSuggestion>[];
    final seenDescriptions = <String>{};
    for (final list in [google, nominatim]) {
      for (final s in list) {
        final key =
            '${s.mainText.toLowerCase()}|${s.secondaryText.toLowerCase()}';
        if (seenDescriptions.add(key)) {
          merged.add(s);
        }
      }
    }

    state = LocationSearchState(suggestions: merged);
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
