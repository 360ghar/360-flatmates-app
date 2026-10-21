import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chats/application/cursor_list_controller.dart';
import '../../features/chats/application/messages_controller.dart';
import '../../features/notifications/notifications_list_controller.dart';
import '../../features/notifications/notifications_repository.dart';
import '../../features/visits/application/visits_list_controller.dart';
import '../../features/visits/visits_repository.dart';
import 'flatmates_realtime_service.dart';

// -- Realtime service singleton (Supabase Broadcast) -------------------------

final flatmatesRealtimeServiceProvider = Provider<FlatmatesRealtimeService>((
  ref,
) {
  final service = FlatmatesRealtimeService();
  ref.onDispose(() => service.dispose());
  return service;
});

// -- Event stream ------------------------------------------------------------

final flatmatesRealtimeEventProvider = StreamProvider<FlatmatesRealtimeEvent>((
  ref,
) {
  final service = ref.watch(flatmatesRealtimeServiceProvider);
  return service.events;
});

// -- Event router ------------------------------------------------------------
// Watches the event stream and invalidates the relevant Riverpod providers
// so the UI refreshes in real-time without manual pull-to-refresh.
//
// Contract matches backend FLATMATES_REALTIME_EVENTS:
// new_match, new_message, conversation_updated, visit_updated,
// listing_status_changed, new_notification.

final flatmatesRealtimeEventRouterProvider = Provider<void>((ref) {
  ref.watch(flatmatesRealtimeEventProvider);

  ref.listen(flatmatesRealtimeEventProvider, (previous, next) {
    final event = next.valueOrNull;
    if (event == null) return;

    routeFlatmatesRealtimeEvent(ref, event);
  });
});

void routeFlatmatesRealtimeEvent(Ref ref, FlatmatesRealtimeEvent event) {
  switch (event.type) {
    case 'new_match':
      _invalidateMatchState(ref);
      break;
    case 'new_notification':
      _routeNotificationEvent(ref, event.data);
      break;
    case 'visit_updated':
      ref.invalidate(visitsProvider);
      ref.invalidate(visitsListControllerProvider);
      break;
    case 'new_message':
    case 'conversation_updated':
      _invalidateConversationState(ref);
      final conversationId =
          _intAt(event.data, const ['conversation_id']) ??
          _intAt(event.data, const ['data', 'conversation_id']);
      if (conversationId != null) {
        _refreshConversationThread(ref, conversationId);
      }
      break;
    case 'listing_status_changed':
      // Listing pages listen for this event type directly.
      break;
    default:
      debugPrint('RealtimeRouter: unhandled event type=${event.type}');
  }
}

void _routeNotificationEvent(Ref ref, Map<String, dynamic> data) {
  ref.invalidate(notificationsListControllerProvider);
  ref.invalidate(notificationsUnreadCountProvider);

  final typeKey =
      _stringAt(data, const ['type_key']) ??
      _stringAt(data, const ['data', 'type_key']) ??
      // Older realtime payloads name the notification with `type`.
      _stringAt(data, const ['type']) ??
      _stringAt(data, const ['data', 'type']);

  switch (typeKey) {
    case 'flatmate_new_message':
    case 'new_message':
      _invalidateConversationState(ref);
      final route =
          _stringAt(data, const ['route']) ??
          _stringAt(data, const ['data', 'route']);
      final conversationId = conversationIdFromRoute(route);
      if (conversationId != null) {
        _refreshConversationThread(ref, conversationId);
      }
      break;
    case 'flatmate_new_match':
    case 'new_match':
      _invalidateMatchState(ref);
      break;
    default:
      debugPrint('RealtimeRouter: unhandled notification typeKey=$typeKey');
  }
}

void _invalidateMatchState(Ref ref) {
  _invalidateConversationState(ref);
  _invalidateLikeState(ref);
}

void _invalidateConversationState(Ref ref) {
  ref.invalidate(conversationsListControllerProvider);
}

/// Refreshes an open thread over HTTP when the user channel broadcasts a
/// message event for it. A thread that is not open reads the newest page when
/// it is opened, so there is nothing to refresh.
void _refreshConversationThread(Ref ref, int conversationId) {
  if (ref.exists(messagesControllerProvider(conversationId))) {
    unawaited(
      ref
          .read(messagesControllerProvider(conversationId).notifier)
          .refetchLatest(),
    );
  }
}

void _invalidateLikeState(Ref ref) {
  ref.invalidate(incomingLikesListControllerProvider);
  ref.invalidate(outgoingLikesListControllerProvider);
}

/// The conversation id of an in-app route (`/chats/{id}`) or a push route
/// (`/flatmates/chat/{id}`).
int? conversationIdFromRoute(String? route) {
  if (route == null) return null;
  final uri = Uri.tryParse(route);
  if (uri == null) return null;
  final segments = uri.pathSegments;
  var index = segments.indexOf('chats');
  if (index < 0) index = segments.indexOf('chat');
  if (index < 0 || index + 1 >= segments.length) return null;
  return int.tryParse(segments[index + 1]);
}

String? _stringAt(Map<String, dynamic> data, List<String> path) {
  Object? cursor = data;
  for (final key in path) {
    if (cursor is! Map) return null;
    cursor = cursor[key];
  }
  return cursor?.toString();
}

int? _intAt(Map<String, dynamic> data, List<String> path) {
  Object? cursor = data;
  for (final key in path) {
    if (cursor is! Map) return null;
    cursor = cursor[key];
  }
  if (cursor is int) return cursor;
  if (cursor is num) return cursor.toInt();
  if (cursor is String) return int.tryParse(cursor);
  return null;
}
