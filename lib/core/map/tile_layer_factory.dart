import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';

/// Shared factory for building a theme-aware [TileLayer] with a long-lived
/// HTTP client to keep connections warm.
///
/// ## Light basemap
/// OpenStreetMap standard cartography (green parks, blue water, hierarchical
/// roads) — natural colors, no color filters.
///
/// ## Dark basemap
/// CARTO `dark_all` with native `@2x` retina support.
///
/// Bump [styleVersion] whenever the tile URL changes so [TileLayer] keys force
/// a full reload.
///
/// OSM tile usage policy: identify the app via [userAgentPackageName], do not
/// use subdomain round-robin on tile.openstreetmap.org, and keep traffic
/// reasonable. For high-traffic production, move to a commercial tile CDN that
/// matches openstreetmap-carto colors.
class TileLayerFactory {
  /// Bump when basemap URL or provider changes — used as [ValueKey].
  static const int styleVersion = 10;

  /// Official OSM raster tiles (no `{s}` subdomains — policy requirement).
  static const String _lightUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// CARTO dark with `{r}` → `@2x` on retina devices.
  static const String _darkUrlTemplate =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

  static const String _lightAttribution = '\u00a9 OpenStreetMap contributors';
  static const String _darkAttribution =
      '\u00a9 OpenStreetMap contributors \u00a9 CARTO';

  /// A shared HTTP client so TLS connections are reused across tile requests
  /// and map instances. Lazily recreated after [dispose].
  static Client? _sharedClient;

  static Client get _client {
    _sharedClient ??= Client();
    return _sharedClient!;
  }

  /// Creates a [TileLayer] configured for the current theme (light/dark).
  static TileLayer build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRetina = MediaQuery.devicePixelRatioOf(context) > 1.5;

    if (isDark) {
      return TileLayer(
        key: const ValueKey('basemap-dark-v$styleVersion'),
        urlTemplate: _darkUrlTemplate,
        subdomains: const ['a', 'b', 'c', 'd'],
        userAgentPackageName: 'com.the360ghar.flatmates',
        tileProvider: NetworkTileProvider(httpClient: _client),
        minZoom: 2,
        maxZoom: 19,
        retinaMode: isRetina,
      );
    }

    return TileLayer(
      key: const ValueKey('basemap-light-v$styleVersion'),
      urlTemplate: _lightUrlTemplate,
      // OSM policy: do not use a/b/c subdomains on tile.openstreetmap.org.
      subdomains: const [],
      userAgentPackageName: 'com.the360ghar.flatmates',
      tileProvider: NetworkTileProvider(httpClient: _client),
      minZoom: 2,
      maxZoom: 19,
      // OSM standard tiles have no `{r}` @2x variant; disable retina so we do
      // not enter simulation mode (zoomOffset -1), which can look soft/wrong.
      retinaMode: false,
    );
  }

  /// Attribution string for [RichAttributionWidget], theme-aware.
  static String attributionFor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _darkAttribution : _lightAttribution;
  }

  /// Default attribution (light / OSM). Prefer [attributionFor] when a
  /// [BuildContext] is available.
  static String get attribution => _lightAttribution;

  /// Cleanup method for tests / app shutdown.
  static void dispose() {
    _sharedClient?.close();
    _sharedClient = null;
  }
}
