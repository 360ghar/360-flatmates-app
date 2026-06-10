import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';

/// Shared factory for building a [TileLayer] backed by OpenStreetMap standard
/// tiles with a long-lived HTTP client to keep connections warm.
///
/// > [!IMPORTANT]
/// > OSM's free tile servers are intended for light individual use, not
/// > production mobile apps. Before shipping, consider a commercial tile
/// > provider (Stadia, Thunderforest, Mapbox) or coordinate with OSM
/// > to avoid being blocked at scale.
class TileLayerFactory {
  static const String _urlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const String _attribution = '\u00a9 OpenStreetMap contributors';

  /// A shared HTTP client so TLS connections are reused across tile requests
  /// and map instances. Lazily recreated after [dispose].
  static Client? _sharedClient;

  static Client get _client {
    _sharedClient ??= Client();
    return _sharedClient!;
  }

  /// Creates a [TileLayer] configured with OpenStreetMap standard tiles and
  /// proper HTTP headers (User-Agent, Referer) required by the OSM tile usage
  /// policy (https://operations.osmfoundation.org/policies/tiles/).
  static TileLayer build(BuildContext context) {
    return TileLayer(
      urlTemplate: _urlTemplate,
      userAgentPackageName: '360Flatmates',
      tileProvider: NetworkTileProvider(
        httpClient: _client,
        headers: {'Referer': 'https://360ghar.com'},
      ),
      minZoom: 2,
      maxZoom: 19,
    );
  }

  /// Returns the OSM attribution string for use in [RichAttributionWidget].
  static String get attribution => _attribution;

  /// Cleanup method for tests / app shutdown.
  static void dispose() {
    _sharedClient?.close();
    _sharedClient = null;
  }
}
