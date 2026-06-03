import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../core/map/map_controller.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../discover_repository.dart';
import 'map_marker_builder.dart';

// Style ids for the search-radius circle (fill + outline) GeoJSON layers.
const String _radiusSourceId = 'search-radius-source';
const String _radiusFillLayerId = 'search-radius-fill';
const String _radiusLineLayerId = 'search-radius-line';

/// The interactive discover map: an OpenFreeMap Liberty vector map with a
/// km-accurate search-radius ring (GeoJSON fill + line) and listing/cluster
/// markers rendered as Flutter widget overlays.
///
/// MARKER STRATEGY — widget overlay (not native symbol layers):
/// The app's markers are rich custom Flutter widgets (price bubble, BHK badge,
/// cluster ring with price range) and the clustering is *locality-based* (done
/// in [buildClusteredMarkers]), not zoom-based. To preserve that exact visual
/// design and the cluster-tap-opens-sheet UX, each marker's geo point is
/// projected to a screen pixel via [MapLibreMapController.toScreenLocation] and
/// the widget is positioned in a [Stack] above the map. Positions are recomputed
/// on every camera move (controller listener) and finalized on `onCameraIdle`.
/// This is viable because marker counts are bounded (one filtered viewport,
/// grouped by locality). Native GeoJSON clustering would change the clustering
/// semantics and hit the Liberty-glyph limitation for custom text labels.
class DiscoverMap extends StatefulWidget {
  const DiscoverMap({
    required this.listings,
    required this.searchRadiusKm,
    required this.initialCenter,
    required this.onMapReady,
    required this.onListingTap,
    required this.onClusterTap,
    this.selectedPropertyId,
    super.key,
  });

  final List<PropertyListing> listings;
  final double searchRadiusKm;
  final LatLng initialCenter;
  final String? selectedPropertyId;

  /// Hands the live wrapper back so the parent page can drive camera moves
  /// (recenter, animate-to-location, fit-bounds).
  final ValueChanged<FlatmatesMapController> onMapReady;
  final void Function(PropertyListing) onListingTap;
  final void Function(List<PropertyListing>) onClusterTap;

  @override
  State<DiscoverMap> createState() => _DiscoverMapState();
}

class _DiscoverMapState extends State<DiscoverMap> {
  final FlatmatesMapController _mapController = FlatmatesMapController();

  List<FlatmatesMapMarker> _markers = const [];
  final Map<String, Offset> _markerScreenPositions = {};
  String _markerSignature = '';
  bool _styleLoaded = false;

  // The center/radius last pushed to the radius GeoJSON source, so we only
  // rebuild it when it actually changes.
  LatLng? _radiusCenter;
  double? _radiusKm;

  @override
  void didUpdateWidget(DiscoverMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-sync the radius ring when the resolved center or radius changes
    // (location pick, recenter, or radius-slider update).
    if (_styleLoaded &&
        (oldWidget.searchRadiusKm != widget.searchRadiusKm ||
            oldWidget.initialCenter.latitude != widget.initialCenter.latitude ||
            oldWidget.initialCenter.longitude !=
                widget.initialCenter.longitude)) {
      _syncRadiusCircle(widget.initialCenter);
    }
  }

  @override
  void dispose() {
    _mapController.controller?.removeListener(_onCameraChanged);
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _markers = buildClusteredMarkers(
      items: widget.listings,
      theme: theme,
      onListingTap: widget.onListingTap,
      onClusterTap: widget.onClusterTap,
      selectedPropertyId: widget.selectedPropertyId,
    );

    // Only reproject after this frame when the marker SET changed (new data),
    // not on every build — _updateOverlays calls setState and would otherwise
    // loop. Camera-driven repositioning is handled by the controller listener
    // and onCameraIdle.
    final signature = _markers.map((m) => m.id).join('|');
    if (signature != _markerSignature) {
      _markerSignature = signature;
      if (_mapController.isAttached) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _updateOverlays());
      }
    }

    return Stack(
      children: [
        MapLibreMap(
          styleString: kLibertyStyle,
          initialCameraPosition: CameraPosition(
            target: widget.initialCenter,
            zoom: kDefaultInitialZoom,
          ),
          minMaxZoomPreference: const MinMaxZoomPreference(
            kDefaultMinZoom,
            kDefaultMaxZoom,
          ),
          // Required so the wrapper can read cameraPosition for zoom-preserving
          // animations and overlay projection.
          trackCameraPosition: true,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          attributionButtonPosition: AttributionButtonPosition.bottomRight,
          onMapCreated: _onMapCreated,
          onStyleLoadedCallback: _onStyleLoaded,
          onCameraIdle: _onCameraIdle,
        ),
        // Marker overlays projected onto the map surface.
        ..._buildMarkerOverlays(),
      ],
    );
  }

  List<Widget> _buildMarkerOverlays() {
    final overlays = <Widget>[];
    for (final marker in _markers) {
      final pos = _markerScreenPositions[marker.id];
      if (pos == null) continue;
      overlays.add(
        Positioned(
          left: pos.dx - marker.size.width / 2,
          // Anchor so the bottom-center (pin tip / cluster) sits on the point.
          top: pos.dy - marker.size.height,
          width: marker.size.width,
          height: marker.size.height,
          child: marker.child,
        ),
      );
    }
    return overlays;
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController.attach(controller);
    // Reproject overlays continuously while the user pans/zooms.
    controller.addListener(_onCameraChanged);
    widget.onMapReady(_mapController);
  }

  void _onCameraChanged() {
    if (!mounted) return;
    _updateOverlays();
  }

  void _onStyleLoaded() {
    // Sources/layers/images must be (re)added here; this can fire again on a
    // style reload, so the sync routine is idempotent (remove-then-add).
    _styleLoaded = true;
    // Force a rebuild of the circle on (re)load.
    _radiusCenter = null;
    _radiusKm = null;
    _syncRadiusCircle(widget.initialCenter);
    _updateOverlays();
  }

  void _onCameraIdle() {
    // Camera settled: finalize overlay positions. This is also the hook where
    // a viewport-driven re-fetch would live, e.g.:
    //   final region = await _mapController.controller!.getVisibleRegion();
    //   ...trigger a re-fetch keyed on the visible bounds...
    _updateOverlays();
  }

  Future<void> _updateOverlays() async {
    if (!mounted || !_mapController.isAttached) return;
    final positions = <String, Offset>{};
    for (final marker in _markers) {
      final p = await _mapController.toScreenLocation(marker.point);
      if (p == null) continue;
      positions[marker.id] = Offset(p.x.toDouble(), p.y.toDouble());
    }
    if (!mounted) return;
    if (_positionsEqual(positions, _markerScreenPositions)) return;
    setState(() {
      _markerScreenPositions
        ..clear()
        ..addAll(positions);
    });
  }

  static bool _positionsEqual(Map<String, Offset> a, Map<String, Offset> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null || (other - entry.value).distanceSquared > 0.25) {
        return false;
      }
    }
    return true;
  }

  Future<void> _syncRadiusCircle(LatLng center) async {
    final controller = _mapController.controller;
    if (controller == null || !_styleLoaded) return;
    final radiusKm = widget.searchRadiusKm;
    if (_radiusCenter?.latitude == center.latitude &&
        _radiusCenter?.longitude == center.longitude &&
        _radiusKm == radiusKm) {
      return;
    }
    _radiusCenter = center;
    _radiusKm = radiusKm;

    final geojson = circlePolygon(center, radiusKm);
    final circleColor = AppSemanticColors.accent;

    // Idempotent (re)create: remove existing layers/source first, ignoring
    // errors when they don't yet exist.
    try {
      await controller.removeLayer(_radiusFillLayerId);
    } catch (_) {}
    try {
      await controller.removeLayer(_radiusLineLayerId);
    } catch (_) {}
    try {
      await controller.removeSource(_radiusSourceId);
    } catch (_) {}

    await controller.addGeoJsonSource(_radiusSourceId, geojson);
    await controller.addFillLayer(
      _radiusSourceId,
      _radiusFillLayerId,
      FillLayerProperties(fillColor: _toHex(circleColor), fillOpacity: 0.15),
    );
    await controller.addLineLayer(
      _radiusSourceId,
      _radiusLineLayerId,
      LineLayerProperties(
        lineColor: _toHex(circleColor),
        lineOpacity: 0.4,
        lineWidth: 1.5,
      ),
    );
  }

  static String _toHex(Color c) {
    final argb = c.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }
}
