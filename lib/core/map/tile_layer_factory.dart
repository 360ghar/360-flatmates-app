import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';

/// Shared factory for building a theme-aware [TileLayer] backed by CARTO
/// basemaps with a long-lived HTTP client to keep connections warm.
///
/// CARTO basemaps are suitable for production mobile use (unlike raw OSM tile
/// servers). Attribution is required; see https://carto.com/legal/ for terms.
/// Before high-traffic launch, confirm usage limits with CARTO or move to a
/// paid tile plan.
class TileLayerFactory {
  static const String _lightUrlTemplate =
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
  static const String _darkUrlTemplate =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

  static const String _attribution =
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
    final urlTemplate = isDark ? _darkUrlTemplate : _lightUrlTemplate;

    return TileLayer(
      urlTemplate: urlTemplate,
      subdomains: const ['a', 'b', 'c', 'd'],
      userAgentPackageName: '360Flatmates',
      tileProvider: NetworkTileProvider(
        httpClient: _client,
        headers: {'Referer': 'https://360ghar.com'},
      ),
      minZoom: 2,
      maxZoom: 19,
      retinaMode: MediaQuery.of(context).devicePixelRatio > 1.5,
    );
  }

  /// Returns the OSM/CARTO attribution string for use in [RichAttributionWidget].
  static String get attribution => _attribution;

  /// Cleanup method for tests / app shutdown.
  static void dispose() {
    _sharedClient?.close();
    _sharedClient = null;
  }
}
