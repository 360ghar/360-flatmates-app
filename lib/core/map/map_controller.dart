import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// OpenFreeMap "Liberty" vector style. No API key required; OSM/OpenFreeMap
/// attribution is rendered automatically by the style and MUST NOT be hidden.
const String kLibertyStyle = 'https://tiles.openfreemap.org/styles/liberty';

/// Default initial zoom level for map views.
const double kDefaultInitialZoom = 12.0;

/// Default minimum zoom level.
const double kDefaultMinZoom = 3.0;

/// Default maximum zoom level.
const double kDefaultMaxZoom = 19.0;

/// Reusable wrapper around [MapLibreMapController] that exposes the small,
/// stable surface the feature pages need (camera moves, zoom, bounds fitting).
///
/// Follows the project's core-layer pattern: pure plumbing, no feature logic.
/// The wrapper holds a *nullable* underlying controller because MapLibre only
/// hands the controller back asynchronously via `onMapCreated`; call
/// [attach] from that callback before invoking any camera method.
///
/// Coordinate convention: every public method here uses MapLibre's [LatLng]
/// (latitude first). GeoJSON helpers in this file emit `[lng, lat]` per the
/// GeoJSON spec — keep that distinction in mind at call sites.
class FlatmatesMapController {
  MapLibreMapController? _controller;

  /// The underlying MapLibre controller, or null until [attach] runs.
  MapLibreMapController? get controller => _controller;

  bool get isAttached => _controller != null;

  /// The most recent camera target, or null if the camera position is unknown.
  /// Requires the map to have been created with `trackCameraPosition: true`.
  LatLng? get center => _controller?.cameraPosition?.target;

  /// The most recent zoom level, or [kDefaultInitialZoom] if unknown.
  double get zoom => _controller?.cameraPosition?.zoom ?? kDefaultInitialZoom;

  /// Bind the live MapLibre controller. Call from `onMapCreated`.
  void attach(MapLibreMapController controller) {
    _controller = controller;
  }

  /// Instantly re-position the camera (no animation).
  Future<void> move(LatLng center, double zoom) async {
    await _controller?.moveCamera(CameraUpdate.newLatLngZoom(center, zoom));
  }

  /// Smoothly animate the camera to [center]. When [zoom] is omitted the
  /// current zoom level is preserved.
  Future<void> animateTo(
    LatLng center, {
    double? zoom,
    Duration duration = const Duration(milliseconds: 400),
  }) async {
    final controller = _controller;
    if (controller == null) return;
    final targetZoom = zoom ?? this.zoom;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(center, targetZoom),
      duration: duration,
    );
  }

  /// Fit the camera so every point in [points] is visible.
  Future<void> fitBounds(
    List<LatLng> points, {
    EdgeInsets padding = const EdgeInsets.all(48),
  }) async {
    final controller = _controller;
    if (controller == null || points.isEmpty) return;

    if (points.length == 1) {
      await animateTo(points.first, zoom: 15);
      return;
    }

    final bounds = boundsFromPoints(points);
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        left: padding.left,
        top: padding.top,
        right: padding.right,
        bottom: padding.bottom,
      ),
    );
  }

  Future<void> zoomIn() async {
    await _controller?.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> zoomOut() async {
    await _controller?.animateCamera(CameraUpdate.zoomOut());
  }

  /// Project a geographic coordinate to a screen pixel, used to position
  /// Flutter widget overlays on top of the map. Returns null if not attached.
  Future<math.Point<num>?> toScreenLocation(LatLng latLng) async {
    final controller = _controller;
    if (controller == null) return null;
    return controller.toScreenLocation(latLng);
  }

  void dispose() {
    // MapLibreMapController is owned/disposed by the MapLibreMap widget itself;
    // we only drop our reference so stale calls become no-ops.
    _controller = null;
  }
}

/// Builds a [LatLngBounds] (MapLibre, latitude-first) enclosing [points].
LatLngBounds boundsFromPoints(List<LatLng> points) {
  assert(points.isNotEmpty);
  var minLat = points.first.latitude;
  var maxLat = points.first.latitude;
  var minLng = points.first.longitude;
  var maxLng = points.first.longitude;
  for (final p in points) {
    minLat = math.min(minLat, p.latitude);
    maxLat = math.max(maxLat, p.latitude);
    minLng = math.min(minLng, p.longitude);
    maxLng = math.max(maxLng, p.longitude);
  }
  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}

const double _earthRadiusMeters = 6378137.0;

/// Generates a closed GeoJSON Polygon (a `FeatureCollection` with one feature)
/// approximating a circle of [radiusKm] around [center], using a haversine
/// destination-point loop with [steps] segments. No external geo deps.
///
/// MapLibre's `CircleLayer` radius is in *pixels*, not meters, so a real
/// km-accurate ring must be drawn as a polygon via fill + line layers.
///
/// Output coordinates are `[lng, lat]` (GeoJSON order).
Map<String, dynamic> circlePolygon(
  LatLng center,
  double radiusKm, {
  int steps = 64,
}) {
  final radiusMeters = radiusKm * 1000.0;
  final latRad = center.latitude * math.pi / 180.0;
  final lngRad = center.longitude * math.pi / 180.0;
  final angularDistance = radiusMeters / _earthRadiusMeters;

  final ring = <List<double>>[];
  for (var i = 0; i <= steps; i++) {
    final bearing = 2 * math.pi * (i / steps);
    final destLatRad = math.asin(
      math.sin(latRad) * math.cos(angularDistance) +
          math.cos(latRad) * math.sin(angularDistance) * math.cos(bearing),
    );
    final destLngRad =
        lngRad +
        math.atan2(
          math.sin(bearing) * math.sin(angularDistance) * math.cos(latRad),
          math.cos(angularDistance) - math.sin(latRad) * math.sin(destLatRad),
        );
    final destLat = destLatRad * 180.0 / math.pi;
    var destLng = destLngRad * 180.0 / math.pi;
    // Normalize longitude into [-180, 180).
    destLng = (destLng + 540.0) % 360.0 - 180.0;
    ring.add([destLng, destLat]);
  }

  return <String, dynamic>{
    'type': 'FeatureCollection',
    'features': <Map<String, dynamic>>[
      {
        'type': 'Feature',
        'properties': <String, dynamic>{},
        'geometry': <String, dynamic>{
          'type': 'Polygon',
          'coordinates': <List<List<double>>>[ring],
        },
      },
    ],
  };
}
