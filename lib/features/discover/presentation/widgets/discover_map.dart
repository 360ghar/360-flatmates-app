import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/map/map_controller.dart';
import '../../../../core/map/tile_layer_factory.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../discover_repository.dart';
import 'map_marker_builder.dart';

class DiscoverMap extends StatefulWidget {
  const DiscoverMap({
    required this.listings,
    required this.initialCenter,
    required this.onMapReady,
    required this.onListingTap,
    required this.onClusterTap,
    this.selectedPropertyId,
    this.userLocation,
    super.key,
  });

  final List<PropertyListing> listings;
  final LatLng initialCenter;
  final String? selectedPropertyId;
  final LatLng? userLocation;

  final ValueChanged<FlatmatesMapController> onMapReady;
  final void Function(PropertyListing) onListingTap;
  final void Function(List<PropertyListing>) onClusterTap;

  @override
  State<DiscoverMap> createState() => _DiscoverMapState();
}

class _DiscoverMapState extends State<DiscoverMap> {
  final FlatmatesMapController _mapController = FlatmatesMapController();
  final MapController _mapImpl = MapController();

  List<FlatmatesMapMarker> _markers = const [];
  String _markerSignature = '';
  bool _styleLoaded = false;

  @override
  void didUpdateWidget(DiscoverMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listings != widget.listings ||
        oldWidget.selectedPropertyId != widget.selectedPropertyId ||
        oldWidget.onListingTap != widget.onListingTap ||
        oldWidget.onClusterTap != widget.onClusterTap) {
      _markerSignature = '';
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _rebuildMarkersIfNeeded() {
    final sig = Object.hash(
      widget.listings.length,
      widget.listings.isEmpty ? 0 : widget.listings.first.id,
      widget.listings.isEmpty ? 0 : widget.listings.last.id,
      widget.selectedPropertyId,
    ).toString();
    if (sig == _markerSignature) return;
    _markerSignature = sig;

    final theme = Theme.of(context);
    _markers = buildClusteredMarkers(
      items: widget.listings,
      theme: theme,
      onListingTap: widget.onListingTap,
      onClusterTap: widget.onClusterTap,
      selectedPropertyId: widget.selectedPropertyId,
    );
  }

  @override
  Widget build(BuildContext context) {
    _rebuildMarkersIfNeeded();

    return Stack(
      children: [
        // Isolate map tile/marker paints from chrome overlays above.
        RepaintBoundary(
          child: FlutterMap(
            mapController: _mapImpl,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: kDefaultInitialZoom,
              minZoom: kDefaultMinZoom,
              maxZoom: kDefaultMaxZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapReady: _onMapReady,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayerFactory.build(context),
              MarkerLayer(markers: _buildMarkers(context)),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    TileLayerFactory.attributionFor(context),
                    textStyle: TextStyle(
                      fontSize: 10,
                      color: AppSemanticColors.textSecondaryFor(
                        Theme.of(context).brightness,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Marker? _buildUserLocationMarker() {
    final loc = widget.userLocation;
    if (loc == null) return null;

    return Marker(
      point: loc,
      width: 28,
      height: 28,
      alignment: Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue.shade700,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers(BuildContext context) {
    if (!_styleLoaded) return [];

    final markers = _markers.map((marker) {
      return Marker(
        point: marker.point,
        width: marker.size.width,
        height: marker.size.height,
        alignment: Alignment.bottomCenter,
        child: marker.child,
      );
    }).toList();

    final userMarker = _buildUserLocationMarker();
    if (userMarker != null) {
      markers.add(userMarker);
    }

    return markers;
  }

  void _onMapReady() {
    _mapController.attach(_mapImpl);
    setState(() {
      _styleLoaded = true;
    });
    widget.onMapReady(_mapController);
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!mounted) return;
    // MarkerLayer auto-reprojects; no manual sync needed.
  }
}
