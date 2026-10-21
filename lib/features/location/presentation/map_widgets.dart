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
import '../../shared/presentation/flatmates_button.dart';

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
    final isTappable = onTap != null;

    // flutter_map still participates in hit-testing even with
    // InteractiveFlag.none, which swallows parent InkWell / GestureDetector
    // taps. When the mini-map is meant to open external maps, ignore pointer
    // events on the map surface so the full Stack (including the "Open in
    // Maps" badge) is tappable.
    final mapLayer = FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15,
        minZoom: kDefaultMinZoom,
        maxZoom: kDefaultMaxZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [TileLayerFactory.build(context)],
    );

    final mapContent = SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          if (isTappable) IgnorePointer(child: mapLayer) else mapLayer,
          // The pin: map is locked on `center`, so screen-center == `center`.
          IgnorePointer(
            child: Padding(
              // Anchor the tip of the pin (icon bottom) on the centre point.
              padding: const EdgeInsets.only(bottom: 40),
              child: Icon(
                Icons.location_on,
                color: AppSemanticColors.clayFor(Theme.of(context).brightness),
                size: 40,
              ),
            ),
          ),
          // Attribution overlay (decorative on tappable mini-maps).
          Positioned(
            bottom: AppSpacing.xs,
            left: AppSpacing.xs,
            child: IgnorePointer(child: _AttributionWidget(isDark: isDark)),
          ),
          // "Open in Maps" affordance — visual only; taps go to the InkWell.
          if (isTappable)
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: IgnorePointer(child: _OpenInMapsHint(isDark: isDark)),
            ),
          // Explicit full-surface hit target so both the badge and the map
          // body reliably open external maps (sector button is separate).
          if (isTappable)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('flat_map_open'),
                  onTap: onTap,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
        ],
      ),
    );

    final clipped = ClipRRect(
      borderRadius: AppRadius.mdBorder,
      child: mapContent,
    );

    if (!isTappable) {
      return clipped;
    }

    return Semantics(
      button: true,
      label: AppLocalizations.of(context).openInMapsLabel,
      child: clipped,
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
            : AppSemanticColors.surfaceFor(Theme.of(context).brightness),
        borderRadius: AppRadius.smBorder,
        boxShadow: [
          AppShadows.floatingFor(isDark ? Brightness.dark : Brightness.light),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.open_in_new_rounded,
            size: 12,
            color: AppSemanticColors.clayFor(Theme.of(context).brightness),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            AppLocalizations.of(context).openInMapsLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppSemanticColors.clayFor(Theme.of(context).brightness),
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
            : AppSemanticColors.surfaceFor(Theme.of(context).brightness),
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
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppSemanticColors.textSecondaryFor(
              Theme.of(context).brightness,
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
    final locale = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapControlButton(
          icon: Icons.my_location_rounded,
          tooltip: locale.mapRecenterTooltip,
          onTap: onRecenter,
          isDark: isDark,
        ),
        if (onFitBounds != null) ...[
          const SizedBox(height: AppSpacing.xs),
          _MapControlButton(
            icon: Icons.crop_free_rounded,
            tooltip: locale.mapFitAllTooltip,
            onTap: onFitBounds!,
            isDark: isDark,
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        _MapControlButton(
          icon: Icons.add_rounded,
          tooltip: locale.mapZoomInTooltip,
          onTap: onZoomIn,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.xs),
        _MapControlButton(
          icon: Icons.remove_rounded,
          tooltip: locale.mapZoomOutTooltip,
          onTap: onZoomOut,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDark;

  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // A 48 dp paper-3 button with the e2 shadow.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppSemanticColors.paper3For(brightness),
        borderRadius: AppRadius.mdBorder,
        boxShadow: AppShadows.e2(brightness),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.mdBorder,
        child: IconButton(
          onPressed: onTap,
          tooltip: tooltip,
          icon: Icon(
            icon,
            size: 22,
            color: AppSemanticColors.textPrimaryFor(brightness),
          ),
          style: IconButton.styleFrom(
            minimumSize: const Size.square(kMinInteractiveDimension),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.mdBorder,
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
    return FlatmatesButton.secondary(
      label: label ?? locale.getDirectionsLabel,
      icon: Icons.directions_rounded,
      onPressed: _launchDirections,
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
