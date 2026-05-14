typedef PlaceDetails = ({double latitude, double longitude, String name});

enum PlaceSuggestionSource { googlePlaces, nominatim }

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final PlaceSuggestionSource source;
  final double? latitude;
  final double? longitude;

  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.source = PlaceSuggestionSource.googlePlaces,
    this.latitude,
    this.longitude,
  });

  PlaceDetails? get resolvedDetails {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return null;

    final name = mainText.isNotEmpty ? mainText : description;
    if (name.isEmpty) return null;

    return (latitude: lat, longitude: lng, name: name);
  }
}
