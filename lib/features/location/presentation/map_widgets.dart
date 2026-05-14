import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';

class MiniMapView extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double height;
  final String? markerLabel;

  const MiniMapView({
    required this.latitude,
    required this.longitude,
    super.key,
    this.height = 200,
    this.markerLabel,
  });

  @override
  Widget build(BuildContext context) {
    final center = LatLng(latitude, longitude);

    return ClipRRect(
      borderRadius: AppRadius.mdBorder,
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.flatmates.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.location_on,
                    color: AppSemanticColors.accent,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MapRadiusCircle extends StatelessWidget {
  final LatLng center;
  final double radiusKm;
  final Color? color;

  const MapRadiusCircle({
    required this.center,
    required this.radiusKm,
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final circleColor = color ?? AppSemanticColors.accent;

    return CircleLayer(
      circles: [
        CircleMarker(
          point: center,
          radius: radiusKm * 1000,
          color: circleColor.withValues(alpha: 0.15),
          borderColor: circleColor.withValues(alpha: 0.4),
          borderStrokeWidth: 1.5,
        ),
      ],
    );
  }
}

class MapControlButtons extends StatelessWidget {
  final VoidCallback onRecenter;
  final VoidCallback? onFitBounds;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const MapControlButtons({
    required this.onRecenter,
    required this.onZoomIn,
    required this.onZoomOut,
    super.key,
    this.onFitBounds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapControlButton(
          icon: Icons.my_location_rounded,
          onTap: onRecenter,
          isDark: isDark,
        ),
        if (onFitBounds != null) ...[
          const SizedBox(height: AppSpacing.xs),
          _MapControlButton(
            icon: Icons.crop_free_rounded,
            onTap: onFitBounds!,
            isDark: isDark,
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        _MapControlButton(
          icon: Icons.add_rounded,
          onTap: onZoomIn,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.xs),
        _MapControlButton(
          icon: Icons.remove_rounded,
          onTap: onZoomOut,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _MapControlButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppSemanticColors.darkSurfaceElevated
            : AppSemanticColors.card,
        borderRadius: AppRadius.smBorder,
        boxShadow: [AppShadows.floatingFor(isDark ? Brightness.dark : Brightness.light)],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.smBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.smBorder,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Icon(
              icon,
              size: 20,
              color: isDark
                  ? AppSemanticColors.paper3
                  : AppSemanticColors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}

class GetDirectionsButton extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? label;

  const GetDirectionsButton({
    required this.latitude,
    required this.longitude,
    super.key,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return OutlinedButton.icon(
      onPressed: _launchDirections,
      icon: const Icon(Icons.directions_rounded, size: 18),
      label: Text(label ?? locale.getDirectionsLabel),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppSemanticColors.accent,
        side: const BorderSide(color: AppSemanticColors.accent),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.smBorder,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }

  Future<void> _launchDirections() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
