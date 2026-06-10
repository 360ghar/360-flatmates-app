import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const double kDefaultInitialZoom = 12.0;

const double kDefaultMinZoom = 3.0;

const double kDefaultMaxZoom = 19.0;

class FlatmatesMapController {
  MapController? _impl;

  MapController? get impl => _impl;

  bool get isAttached => _impl != null;

  LatLng get center => _impl?.camera.center ?? const LatLng(28.4595, 77.0266);

  double get zoom => _impl?.camera.zoom ?? kDefaultInitialZoom;

  LatLngBounds get visibleBounds =>
      _impl?.camera.visibleBounds ??
      LatLngBounds(const LatLng(0, 0), const LatLng(0, 0));

  void attach(MapController controller) {
    _impl = controller;
  }

  Future<void> move(LatLng target, double zoom) async {
    _impl?.move(target, zoom);
  }

  Future<void> animateTo(
    LatLng center, {
    double? zoom,
    Duration duration = const Duration(milliseconds: 400),
  }) async {
    final ctrl = _impl;
    if (ctrl == null) return;
    final targetZoom = zoom ?? ctrl.camera.zoom;
    ctrl.move(center, targetZoom);
  }

  Future<void> fitBounds(
    List<LatLng> points, {
    EdgeInsets padding = const EdgeInsets.all(48),
  }) async {
    final ctrl = _impl;
    if (ctrl == null || points.isEmpty) return;

    if (points.length == 1) {
      await animateTo(points.first, zoom: 15);
      return;
    }

    final bounds = boundsFromPoints(points);
    ctrl.fitCamera(CameraFit.bounds(bounds: bounds, padding: padding));
  }

  Future<void> zoomIn() async {
    final ctrl = _impl;
    if (ctrl == null) return;
    ctrl.move(ctrl.camera.center, ctrl.camera.zoom + 1);
  }

  Future<void> zoomOut() async {
    final ctrl = _impl;
    if (ctrl == null) return;
    ctrl.move(ctrl.camera.center, ctrl.camera.zoom - 1);
  }

  Offset? pointToScreen(LatLng point) {
    return _impl?.camera.latLngToScreenOffset(point);
  }

  LatLng? screenToPoint(Offset point) {
    return _impl?.camera.screenOffsetToLatLng(point);
  }

  void dispose() {
    _impl = null;
  }
}

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
  return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
}

const double _earthRadiusMeters = 6378137.0;

List<LatLng> circlePoints(LatLng center, double radiusKm, {int steps = 64}) {
  final radiusMeters = radiusKm * 1000.0;
  final latRad = center.latitude * math.pi / 180.0;
  final lngRad = center.longitude * math.pi / 180.0;
  final angularDistance = radiusMeters / _earthRadiusMeters;

  final ring = <LatLng>[];
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
    destLng = (destLng + 540.0) % 360.0 - 180.0;
    ring.add(LatLng(destLat, destLng));
  }

  return ring;
}
