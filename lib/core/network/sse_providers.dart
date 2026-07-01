import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chats/chats_repository.dart';
import '../../features/chats/application/cursor_list_controller.dart';
import '../../features/notifications/notifications_repository.dart';
import '../../features/visits/visits_repository.dart';
import 'sse_service.dart';

// -- SSE service singleton ---------------------------------------------------

final sseServiceProvider = Provider<SseService>((ref) {
  final service = SseService();
  ref.onDispose(() => service.dispose());
  return service;
});

// -- SSE event stream --------------------------------------------------------

final sseEventProvider = StreamProvider<SseEvent>((ref) {
  final service = ref.watch(sseServiceProvider);
  // Stream is safe to access before connect — returns an empty broadcast stream.
  return service.events;
});

// -- SSE event router --------------------------------------------------------
// Watches the event stream and invalidates the relevant Riverpod providers
// so the UI refreshes in real-time without manual pull-to-refresh or polling.

final sseEventRouterProvider = Provider<void>((ref) {
  // Watching the stream provider activates it.
  ref.watch(sseEventProvider);

  ref.listen(sseEventProvider, (previous, next) {
    final event = next.valueOrNull;
    if (event == null) return;

    routeFlatmatesSseEvent(ref, event);
  });
});

void routeFlatmatesSseEvent(Ref ref, SseEvent event) {
  switch (event.type) {
    case 'new_match':
      _invalidateMatchState(ref);
      break;
    case 'swipe':
      if (_boolAt(event.data, const ['data', 'did_match']) ||
          _boolAt(event.data, const ['did_match'])) {
        _invalidateMatchState(ref);
      }
      break;
    case 'new_like':
    case 'incoming_like':
      _invalidateLikeState(ref);
      break;
    case 'new_notification':
      _routeNotificationEvent(ref, event.data);
      break;
    case 'visit_updated':
      ref.invalidate(visitsProvider);
      break;
    default:
      debugPrint('SseRouter: unhandled event type=${event.type}');
  }
}

void _routeNotificationEvent(Ref ref, Map<String, dynamic> data) {
  ref.invalidate(notificationsProvider);

  final typeKey =
      _stringAt(data, const ['type_key']) ??
      _stringAt(data, const ['data', 'type_key']) ??
      _stringAt(data, const ['type']);

  switch (typeKey) {
    case 'flatmate_new_message':
    case 'new_message':
      _invalidateConversationState(ref);
      final route =
          _stringAt(data, const ['route']) ??
          _stringAt(data, const ['data', 'route']);
      final conversationId = conversationIdFromRoute(route);
      if (conversationId != null) {
        // Invalidate the REST seed so the next read pulls a fresh page.
        // The realtime stream (messagesStreamProvider) stays open — it
        // is the source of truth while the thread is mounted, and
        // invalidating it would tear down the Supabase subscription on
        // every inbound event.
        ref.invalidate(messagesProvider(conversationId));
      }
      break;
    case 'flatmate_new_match':
    case 'new_match':
      _invalidateMatchState(ref);
      break;
    default:
      debugPrint('SseRouter: unhandled notification typeKey=$typeKey');
  }
}

void _invalidateMatchState(Ref ref) {
  _invalidateConversationState(ref);
  _invalidateLikeState(ref);
}

void _invalidateConversationState(Ref ref) {
  ref.invalidate(conversationsProvider);
  ref.invalidate(conversationsListControllerProvider);
}

void _invalidateLikeState(Ref ref) {
  ref.invalidate(incomingLikesProvider);
  ref.invalidate(outgoingLikesProvider);
  ref.invalidate(incomingLikesListControllerProvider);
  ref.invalidate(outgoingLikesListControllerProvider);
}

int? conversationIdFromRoute(String? route) {
  if (route == null) return null;
  final uri = Uri.tryParse(route);
  if (uri == null) return null;
  final segments = uri.pathSegments;
  final chatsIndex = segments.indexOf('chats');
  if (chatsIndex < 0 || chatsIndex + 1 >= segments.length) return null;
  return int.tryParse(segments[chatsIndex + 1]);
}

String? _stringAt(Map<String, dynamic> data, List<String> path) {
  Object? cursor = data;
  for (final key in path) {
    if (cursor is! Map) return null;
    cursor = cursor[key];
  }
  return cursor?.toString();
}

bool _boolAt(Map<String, dynamic> data, List<String> path) {
  Object? cursor = data;
  for (final key in path) {
    if (cursor is! Map) return false;
    cursor = cursor[key];
  }
  return cursor == true;
}
