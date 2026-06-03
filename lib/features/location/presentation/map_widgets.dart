import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/map/map_controller.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Canonical "simple map" example: a non-interactive MapLibre map centered on a
/// single coordinate with one pin. Because all gestures are disabled the camera
/// can never move, so the pin is drawn as a centered Flutter overlay instead of
/// a map symbol — this avoids depending on the style's glyph/sprite sheet and
/// keeps the marker pixel-perfect.
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            MapLibreMap(
              styleString: kLibertyStyle,
              initialCameraPosition: CameraPosition(target: center, zoom: 15),
              // Fully non-interactive single-pin map.
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              dragEnabled: false,
              doubleClickZoomEnabled: false,
              compassEnabled: false,
              myLocationEnabled: false,
              // Keep attribution visible per OSM/OpenFreeMap license.
              attributionButtonPosition: AttributionButtonPosition.bottomRight,
            ),
            // The pin: map is locked on `center`, so screen-center == `center`.
            IgnorePointer(
              child: Padding(
                // Anchor the tip of the pin (icon bottom) on the centre point.
                padding: const EdgeInsets.only(bottom: 40),
                child: Icon(
                  Icons.location_on,
                  color: AppSemanticColors.accent,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ),
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
        boxShadow: [
          AppShadows.floatingFor(isDark ? Brightness.dark : Brightness.light),
        ],
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
              color: isDark ? AppSemanticColors.paper3 : AppSemanticColors.ink2,
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
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
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
