import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../discover_repository.dart';

/// Builds clustered map markers from a list of property listings.
///
/// Groups listings by locality (or rounded coordinates as fallback).
/// Single-item groups get normal markers; multi-item groups get cluster markers.
Set<Marker> buildClusteredMarkers({
  required List<PropertyListing> items,
  required ThemeData theme,
  required Map<int, BitmapDescriptor> clusterIconCache,
  required void Function(PropertyListing) onListingTap,
  required void Function(List<PropertyListing>) onClusterTap,
}) {
  // Step 1: Group by locality (or by rounded coordinates as fallback).
  final groups = <String, List<PropertyListing>>{};
  for (final item in items) {
    if (item.latitude == null || item.longitude == null) continue;
    final key = item.locality?.trim().isNotEmpty == true
        ? item.locality!.trim().toLowerCase()
        : '${(item.latitude! * 100).round() / 100},${(item.longitude! * 100).round() / 100}';
    groups.putIfAbsent(key, () => []).add(item);
  }

  final markers = <Marker>{};

  for (final entry in groups.entries) {
    final groupItems = entry.value;

    if (groupItems.length == 1) {
      // Single listing — normal marker.
      final item = groupItems.first;
      final isRoom = item.ownerId != null;
      markers.add(
        Marker(
          markerId: MarkerId('listing_${item.id}'),
          position: LatLng(item.latitude!, item.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isRoom ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueBlue,
          ),
          infoWindow: InfoWindow(
            title: item.title,
            snippet: '₹${item.monthlyRent.toStringAsFixed(0)}/mo',
          ),
          onTap: () => onListingTap(item),
        ),
      );
    } else {
      // Cluster marker — use average position of all items in group.
      final avgLat =
          groupItems.map((i) => i.latitude!).reduce((a, b) => a + b) /
          groupItems.length;
      final avgLng =
          groupItems.map((i) => i.longitude!).reduce((a, b) => a + b) /
          groupItems.length;

      markers.add(
        Marker(
          markerId: MarkerId('cluster_${entry.key}'),
          position: LatLng(avgLat, avgLng),
          icon: _getClusterIcon(groupItems.length, clusterIconCache),
          infoWindow: InfoWindow(
            title:
                '${groupItems.length} ${groupItems.first.locality ?? 'listings'}',
            snippet: '${groupItems.length} listings',
          ),
          onTap: () => onClusterTap(groupItems),
        ),
      );
    }
  }

  return markers;
}

/// Returns a [BitmapDescriptor] for a cluster marker with the given count.
BitmapDescriptor _getClusterIcon(
  int count,
  Map<int, BitmapDescriptor> clusterIconCache,
) {
  return clusterIconCache.putIfAbsent(
    count,
    () => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
  );
}
