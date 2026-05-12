import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Reusable map controller wrapper that encapsulates [MapController]
/// and provides convenient methods for camera movement, zoom, etc.
///
/// Follows the project's core-layer pattern: pure plumbing, no feature logic.
/// Use via [mapControllerProvider] or instantiate directly in feature pages.
class FlatmatesMapController {
  FlatmatesMapController() : _mapController = MapController();

  final MapController _mapController;
  MapController get controller => _mapController;

  LatLng? _cachedCenter;
  double _cachedZoom = kDefaultInitialZoom;

  /// Moves the camera to [center] at the given [zoom] level.
  void move(LatLng center, double zoom) {
    _cachedCenter = center;
    _cachedZoom = zoom;
    _mapController.move(center, zoom);
  }

  /// Moves the camera with an optional animation (fitBounds-style).
  ///
  /// Since flutter_map's MapController doesn't have a built-in animateTo,
  /// we use [move] which is synchronous. For animated transitions,
  /// consider wrapping with AnimatedContainer or using the
  /// [MapControllerImpl.move] with a custom approach.
  Future<void> animateTo(LatLng center, {double zoom = 14}) async {
    move(center, zoom);
  }

  /// Fits the map bounds to show all [points] with optional [padding].
  void fitBounds(List<LatLng> points, {EdgeInsets padding = const EdgeInsets.all(48)}) {
    if (points.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: padding,
      ),
    );
  }

  /// Zooms in by one step.
  void zoomIn() {
    move(_cachedCenter ?? LatLng(12.9716, 77.5946), _cachedZoom + 1);
  }

  /// Zooms out by one step.
  void zoomOut() {
    move(_cachedCenter ?? LatLng(12.9716, 77.5946), _cachedZoom - 1);
  }

  /// Current center position of the map (last known position).
  LatLng get center => _cachedCenter ?? LatLng(12.9716, 77.5946);

  /// Current zoom level of the map (last known value).
  double get zoom => _cachedZoom;

  void dispose() {
    // MapController does not need explicit disposal in flutter_map.
  }
}

/// Default OpenStreetMap tile URL template used across the app.
const String kDefaultOsmTileUrl =
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Maximum zoom level for OSM tiles.
const double kDefaultMaxZoom = 19.0;

/// Default initial zoom level for map views.
const double kDefaultInitialZoom = 12.0;

/// Default minimum zoom level.
const double kDefaultMinZoom = 3.0;

/// Creates a default [TileLayer] configured for OpenStreetMap tiles.
///
/// Use this factory to ensure consistent tile configuration across all
/// map instances in the app.
TileLayer createOsmTileLayer({
  String? templateUrl,
  double maxZoom = kDefaultMaxZoom,
  double minZoom = kDefaultMinZoom,
  bool retinaMode = true,
}) {
  return TileLayer(
    urlTemplate: templateUrl ?? kDefaultOsmTileUrl,
    userAgentPackageName: 'com.the360ghar.flatmates',
    maxZoom: maxZoom,
    minZoom: minZoom,
    retinaMode: retinaMode,
  );
}
