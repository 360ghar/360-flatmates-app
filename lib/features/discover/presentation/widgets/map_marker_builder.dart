import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../discover_repository.dart';

/// Builds clustered map markers from a list of property listings.
///
/// Groups listings by locality (or rounded coordinates as fallback).
/// Single-item groups get normal markers; multi-item groups get cluster markers.
///
/// Returns a list of [Marker] widgets compatible with flutter_map's [FlutterMap].
List<Marker> buildClusteredMarkers({
  required List<PropertyListing> items,
  required ThemeData theme,
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

  final markers = <Marker>[];

  for (final entry in groups.entries) {
    final groupItems = entry.value;

    if (groupItems.length == 1) {
      // Single listing — normal marker.
      final item = groupItems.first;
      final isRoom = item.ownerId != null;
      final color =
          isRoom ? const Color(0xFFFF9800) : const Color(0xFF2196F3);
      markers.add(
        Marker(
          point: LatLng(item.latitude!, item.longitude!),
          width: 40,
          height: 40,
          child: _ListingMarkerWidget(
            title: item.title,
            price: item.monthlyRent.toInt(),
            color: color,
            onTap: () => onListingTap(item),
          ),
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
          point: LatLng(avgLat, avgLng),
          width: 48,
          height: 48,
          child: _ClusterMarkerWidget(
            count: groupItems.length,
            label: groupItems.first.locality ?? 'listings',
            onTap: () => onClusterTap(groupItems),
          ),
        ),
      );
    }
  }

  return markers;
}

/// Custom widget for single listing markers on the map.
class _ListingMarkerWidget extends StatelessWidget {
  const _ListingMarkerWidget({
    required this.title,
    required this.price,
    required this.color,
    required this.onTap,
  });

  final String title;
  final int price;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: color, width: 2.5),
        ),
        child: Center(
          child: Icon(
            Icons.home_rounded,
            size: 20,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Custom widget for cluster markers showing listing count.
class _ClusterMarkerWidget extends StatelessWidget {
  const _ClusterMarkerWidget({
    required this.count,
    required this.label,
    required this.onTap,
  });

  final int count;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final clusterColor = const Color(0xFF673AB7);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: clusterColor.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: clusterColor, width: 2.5),
        ),
        child: Center(
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: clusterColor,
            ),
          ),
        ),
      ),
    );
  }
}
