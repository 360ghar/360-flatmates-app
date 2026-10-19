import '../../core/deep_links/deep_link_service.dart';

/// Shared deep-link remapping for in-app notification taps and push payloads.
///
/// The backend sends the shareable link paths of the deep-link registry
/// (`/flatmates/chat/{id}`, `/flatmates/listing/{id}`), which are mapped to the
/// in-app routes (`/chats/{id}`, `/flat-details/{id}`). It may still emit
/// legacy shell paths (`/visits`, `/post`). The app shell mounts visits under
/// profile and listing creation under `/post/new`.
String? resolveNotificationDeepLink(String route) {
  if (!route.startsWith('/')) return null;
  final uri = Uri.tryParse(route);
  if (uri == null) return null;
  final linked = DeepLinkService.internalPathForRoute(route);
  if (linked != null) return linked;
  final path = uri.path;
  final query = uri.hasQuery ? '?${uri.query}' : '';
  if (path == '/post') return '/post/new$query';
  if (path == '/visits' || path.startsWith('/visits/')) {
    return '/profile/visits$query';
  }
  return route;
}

/// Resolves an in-app notification list item to a GoRouter location.
///
/// Prefers an explicit [route] from the backend when present; otherwise falls
/// back to [type] + [referenceId] conventions.
String? resolveNotificationRoute({
  String? route,
  required String type,
  int? referenceId,
}) {
  final explicitRoute = route;
  if (explicitRoute != null && explicitRoute.startsWith('/')) {
    return resolveNotificationDeepLink(explicitRoute);
  }

  switch (type) {
    case 'new_match':
    case 'flatmate_new_match':
    case 'new_message':
    case 'flatmate_new_message':
      if (referenceId != null) {
        return '/chats/$referenceId';
      }
      return null;
    case 'listing_approved':
    case 'flatmate_listing_approved':
      if (referenceId != null) {
        return '/flat-details/$referenceId';
      }
      return '/post/new';
    case 'visit_scheduled':
    case 'flatmate_visit_scheduled':
    case 'visit_confirmed':
    case 'flatmate_visit_confirmed':
      return '/profile/visits';
    default:
      return null;
  }
}
