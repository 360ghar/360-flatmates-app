import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Parses incoming HTTP deep links and routes them via GoRouter.
///
/// Supported paths:
///   /flatmates/listing/{id}  → /flat-details/{id}
///   /flatmates/chat/{id}     → /chats/{id}
///   /flatmates?city={city}   → /waitlist?city={city}
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

    final listingMatch = RegExp(r'^/flatmates/listing/(\d+)').firstMatch(path);
    if (listingMatch != null) {
      final raw = listingMatch.group(1)!;
      if (_isValidId(raw)) return '/flat-details/$raw';
    }

    final chatMatch = RegExp(r'^/flatmates/chat/(\d+)').firstMatch(path);
    if (chatMatch != null) {
      final raw = chatMatch.group(1)!;
      if (_isValidId(raw)) return '/chats/$raw';
    }

    return null;
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
