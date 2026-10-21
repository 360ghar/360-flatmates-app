import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Parses incoming deep links and routes them via GoRouter.
///
/// HTTPS links (path based):
///   /flatmates/listing/{id}  → /flat-details/{id}
///   /flatmates/chat/{id}     → /chats/{id}
///   /flatmates?city={city}   → /waitlist?city={city}
///
/// Custom-scheme links (`com.the360ghar.flatmates360://{entity}/{id}`). The
/// entity is the URI host and the id is the first path segment:
///   chat/{id}                → /chats/{id}
///   listing/{id}             → /flat-details/{id}
class DeepLinkService {
  DeepLinkService({required GoRouter router}) : _router = router;

  final GoRouter _router;
  StreamSubscription<Uri>? _linkSubscription;
  AppLinks? _appLinks;

  static String? _pendingDeepLinkPath;

  static String? consumePendingDeepLink() {
    final path = _pendingDeepLinkPath;
    _pendingDeepLinkPath = null;
    return path;
  }

  /// Drops a captured-but-unconsumed deep link.
  ///
  /// The pending path is static and outlives a session, so it must be cleared
  /// on logout: otherwise a link tapped before an abandoned login replays for
  /// whichever account signs in next on this device.
  static void clearPendingDeepLink() {
    _pendingDeepLinkPath = null;
  }

  void init() {
    if (kIsWeb) return;

    _appLinks = AppLinks();

    _appLinks!
        .getInitialLink()
        .then((uri) {
          if (uri != null) {
            final path = _mapPath(uri);
            if (path != null) {
              _routeToPath(path);
            }
          }
        })
        .catchError((error) {
          debugPrint('[DeepLinkService] getInitialLink error: $error');
        });

    _linkSubscription = _appLinks!.uriLinkStream.listen(
      _handleDeepLink,
      onError: (error) {
        debugPrint('[DeepLinkService] Link stream error: $error');
      },
    );
  }

  /// Stop listening. Call from `dispose`.
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }

  /// Map an incoming URI to an internal GoRouter path and navigate.
  void _handleDeepLink(Uri uri) {
    debugPrint('[DeepLinkService] Incoming deep link: $uri');
    final path = _mapPath(uri);
    if (path != null) {
      debugPrint('[DeepLinkService] Routing to: $path');
      _routeToPath(path);
    } else {
      debugPrint('[DeepLinkService] No mapping for path: ${uri.path}');
    }
  }

  void _routeToPath(String path) {
    _pendingDeepLinkPath = path;
    _router.go(path);
  }

  /// Converts an external URI path to an internal GoRouter path.
  ///
  /// Returns `null` if the path does not match any known pattern
  /// or contains an invalid resource ID.
  static String? _mapPath(Uri uri) {
    if (uri.hasScheme && uri.scheme != 'https' && uri.scheme != 'http') {
      // Only this app's own schemes (AndroidManifest and Info.plist): a link
      // with any other scheme is not ours to route.
      return _appSchemes.contains(uri.scheme) ? _mapSchemeLink(uri) : null;
    }
    final path = uri.path;
    if (path == '/flatmates') {
      final city = uri.queryParameters['city']?.trim();
      if (city != null && city.isNotEmpty) {
        return Uri(
          path: '/waitlist',
          queryParameters: {'city': city},
        ).toString();
      }
      return '/discover';
    }

    final listingMatch = RegExp(
      r'^/flatmates/listing/(\d+)/?$',
    ).firstMatch(path);
    if (listingMatch != null) {
      final raw = listingMatch.group(1)!;
      if (_isValidId(raw)) return '/flat-details/$raw';
    }

    final chatMatch = RegExp(r'^/flatmates/chat/(\d+)/?$').firstMatch(path);
    if (chatMatch != null) {
      final raw = chatMatch.group(1)!;
      if (_isValidId(raw)) return '/chats/$raw';
    }

    return null;
  }

  static const _appSchemes = {
    'com.the360ghar.flatmates360',
    'com.the360ghar.flatmates',
  };

  /// Maps `scheme://chat/42` and `scheme://listing/42`: the entity is the host
  /// and the id is the first path segment.
  static String? _mapSchemeLink(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    final id = segments.first;
    if (!_isValidId(id)) return null;
    return switch (uri.host) {
      'listing' => '/flat-details/$id',
      'chat' => '/chats/$id',
      _ => null,
    };
  }

  /// Ensure the ID is a valid positive integer (not zero, not negative, no
  /// leading zeros beyond a single zero, no overflow).
  static bool _isValidId(String raw) {
    if (raw.isEmpty) return false;
    if (raw == '0') return false;
    if (raw.length > 1 && raw.startsWith('0')) return false;
    final id = int.tryParse(raw);
    return id != null && id > 0;
  }

  @visibleForTesting
  static String? internalPathForUri(Uri uri) => _mapPath(uri);

  /// The in-app route of a backend route (a push `data.route` or a
  /// notification `route`, for example `/flatmates/chat/42`), or null when the
  /// route is not one of the shareable links.
  static String? internalPathForRoute(String route) {
    final uri = Uri.tryParse(route);
    return uri == null ? null : _mapPath(uri);
  }

  /// Builds a public deep link URL for a listing.
  static String listingUrl(int listingId) =>
      'https://the360ghar.com/flatmates/listing/$listingId';

  /// Builds a public deep link URL for a chat.
  static String chatUrl(int chatId) =>
      'https://the360ghar.com/flatmates/chat/$chatId';

  /// Builds the public 360 FlatMates entry URL.
  static String flatmatesUrl({String? city}) {
    final normalizedCity = city?.trim();
    return Uri.https(
      'the360ghar.com',
      '/flatmates',
      normalizedCity == null || normalizedCity.isEmpty
          ? null
          : {'city': normalizedCity},
    ).toString();
  }
}
