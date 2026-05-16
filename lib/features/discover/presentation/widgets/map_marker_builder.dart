import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../discover_repository.dart';

String _formatCompactPrice(int amount) {
  if (amount >= 100000) {
    final lakhs = amount / 100000;
    final value = lakhs.toStringAsFixed(lakhs >= 10 ? 1 : 2);
    final compact = value.replaceAll(RegExp(r'\.?0+$'), '');
    return '₹${compact}L';
  }
  final thousands = amount / 1000;
  return '₹${thousands.toStringAsFixed(thousands == thousands.roundToDouble() ? 0 : 1)}K';
}

List<Marker> buildClusteredMarkers({
  required List<PropertyListing> items,
  required ThemeData theme,
  required void Function(PropertyListing) onListingTap,
  required void Function(List<PropertyListing>) onClusterTap,
}) {
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
      final item = groupItems.first;
      final isRoom = item.ownerId != null;
      final color =
          isRoom ? const Color(0xFFFF9800) : const Color(0xFF2196F3);
      markers.add(
        Marker(
          point: LatLng(item.latitude!, item.longitude!),
          width: 72,
          height: 68,
          child: _ListingMarkerWidget(
            price: item.monthlyRent.toInt(),
            color: color,
            bedrooms: item.bedrooms,
            sharingType: item.sharingType,
            onTap: () => onListingTap(item),
          ),
        ),
      );
    } else {
      final avgLat =
          groupItems.map((i) => i.latitude!).reduce((a, b) => a + b) /
          groupItems.length;
      final avgLng =
          groupItems.map((i) => i.longitude!).reduce((a, b) => a + b) /
          groupItems.length;

      markers.add(
        Marker(
          point: LatLng(avgLat, avgLng),
          width: 56,
          height: 70,
          child: _ClusterMarkerWidget(
            clusterItems: groupItems,
            label: groupItems.first.locality ?? 'listings',
            onTap: () => onClusterTap(groupItems),
          ),
        ),
      );
    }
  }

  return markers;
}

class _ListingMarkerWidget extends StatelessWidget {
  const _ListingMarkerWidget({
    required this.price,
    required this.color,
    required this.onTap,
    this.bedrooms,
    this.sharingType,
  });

  final int price;
  final Color color;
  final VoidCallback onTap;
  final int? bedrooms;
  final String? sharingType;

  @override
  Widget build(BuildContext context) {
    final priceText = _formatCompactPrice(price);

    String? bhkLabel;
    if (bedrooms != null) {
      if (bedrooms == 1) {
        bhkLabel = '1 RK';
      } else if (bedrooms! >= 2) {
        bhkLabel = '$bedrooms BHK';
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        height: 68,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs + 1,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppRadius.md),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    priceText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                CustomPaint(
                  size: const Size(12, 8),
                  painter: _TrianglePainter(color: color),
                ),
              ],
            ),
            if (bhkLabel != null)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.smBorder,
                    border: Border.all(color: color, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    bhkLabel,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      color != oldDelegate.color;
}

class _ClusterMarkerWidget extends StatelessWidget {
  const _ClusterMarkerWidget({
    required this.clusterItems,
    required this.label,
    required this.onTap,
  });

  final List<PropertyListing> clusterItems;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final clusterColor = const Color(0xFF673AB7);
    final count = clusterItems.length;

    final rents = clusterItems
        .map((i) => i.monthlyRent.toInt())
        .toList()
      ..sort();
    final minRent = rents.first;
    final maxRent = rents.last;
    final rangeText = minRent == maxRent
        ? _formatCompactPrice(minRent)
        : '${_formatCompactPrice(minRent)}-${_formatCompactPrice(maxRent)}';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        height: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
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
            const SizedBox(height: 2),
            Text(
              rangeText,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: clusterColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
