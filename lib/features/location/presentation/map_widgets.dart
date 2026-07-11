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

  /// When provided, the whole map becomes tappable (e.g. to open the location
  /// in an external maps app). When null, the map stays purely non-interactive.
  final VoidCallback? onTap;

  const MiniMapView({
    required this.latitude,
    required this.longitude,
    super.key,
    this.height = 200,
    this.markerLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final center = LatLng(latitude, longitude);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mapContent = SizedBox(
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
                    TileLayerFactory.attributionFor(context),
                    textStyle: TextStyle(
                      fontSize: 8,
                      color: AppSemanticColors.textSecondaryFor(
                        isDark ? Brightness.dark : Brightness.light,
                      ),
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
          // "Tap to open" affordance — only shown when the map is tappable.
          if (onTap != null)
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: IgnorePointer(child: _OpenInMapsHint(isDark: isDark)),
            ),
        ],
      ),
    );

    final clipped = ClipRRect(
      borderRadius: AppRadius.mdBorder,
      child: mapContent,
    );

    if (onTap == null) {
      return clipped;
    }

    return Semantics(
      button: true,
      label: AppLocalizations.of(context).openInMapsLabel,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.mdBorder,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('flat_map_open'),
          onTap: onTap,
          borderRadius: AppRadius.mdBorder,
          child: mapContent,
        ),
      ),
    );
  }
}

/// Small frosted badge hinting that the map can be opened externally.
class _OpenInMapsHint extends StatelessWidget {
  final bool isDark;

  const _OpenInMapsHint({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.open_in_new_rounded,
            size: 12,
            color: AppSemanticColors.accent,
          ),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context).openInMapsLabel,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppSemanticColors.accent,
            ),
          ),
        ],
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
          TileLayerFactory.attributionFor(context),
          style: TextStyle(
            fontSize: 8,
            color: AppSemanticColors.textSecondaryFor(
              isDark ? Brightness.dark : Brightness.light,
            ),
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
              color: AppSemanticColors.textSecondaryFor(
                isDark ? Brightness.dark : Brightness.light,
              ),
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
    // Universal Google Maps directions URL — opens the native app or web.
    // Not gated on canLaunchUrl(): unreliable on Android 11+ (package
    // visibility), returns false for https without a <queries> entry.
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    );
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        debugPrint(
          'GetDirectionsButton._launchDirections: launchUrl returned false',
        );
      }
    } catch (e) {
      debugPrint('GetDirectionsButton._launchDirections: $e');
    }
  }
}
