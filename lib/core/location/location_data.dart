class LocationData {
  final String name;
  final double latitude;
  final double longitude;

  const LocationData({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  /// False for missing coordinates: non-finite, or 0,0 (a catalog city with
  /// no latitude/longitude arrives as 0,0).
  bool get hasCoordinates =>
      latitude.isFinite &&
      longitude.isFinite &&
      !(latitude == 0 && longitude == 0);

  String get displayText => name.isNotEmpty ? name : 'Select Location';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationData &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(name, latitude, longitude);
}
