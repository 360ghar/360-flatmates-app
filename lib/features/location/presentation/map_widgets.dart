import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/map/map_controller.dart';
import '../../../core/map/tile_layer_factory.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Canonical "simple map" example: a non-interactive flutter_map centered on a
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: AppRadius.mdBorder,
      child: SizedBox(
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15,
                minZoom: kDefaultMinZoom,
                maxZoom: kDefaultMaxZoom,
                // Fully non-interactive single-pin map.
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayerFactory.build(context),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      TileLayerFactory.attribution,
                      textStyle: TextStyle(
                        fontSize: 8,
                        color: isDark
                            ? AppSemanticColors.paper3
                            : AppSemanticColors.ink2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // The pin: map is locked on `center`, so screen-center == `center`.
            const IgnorePointer(
              child: Padding(
                // Anchor the tip of the pin (icon bottom) on the centre point.
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(
                  Icons.location_on,
                  color: AppSemanticColors.accent,
                  size: 40,
                ),
              ),
            ),
            // Attribution overlay
            Positioned(
              bottom: AppSpacing.xs,
              left: AppSpacing.xs,
              child: _AttributionWidget(isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttributionWidget extends StatelessWidget {
  final bool isDark;

  const _AttributionWidget({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
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
        child: Text(
          TileLayerFactory.attribution,
          style: TextStyle(
            fontSize: 8,
            color: isDark ? AppSemanticColors.paper3 : AppSemanticColors.ink2,
          ),
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
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
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
