import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chats/chats_repository.dart';
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

    switch (event.type) {
      case 'new_message':
      case 'conversation_updated':
      case 'conversation_read':
        ref.invalidate(conversationsProvider);
        break;
      case 'new_match':
        ref.invalidate(conversationsProvider);
        ref.invalidate(incomingLikesProvider);
        ref.invalidate(outgoingLikesProvider);
        break;
      case 'new_like':
      case 'incoming_like':
        ref.invalidate(incomingLikesProvider);
        ref.invalidate(outgoingLikesProvider);
        break;
      case 'new_notification':
        ref.invalidate(notificationsProvider);
        break;
      case 'visit_updated':
        ref.invalidate(visitsProvider);
        break;
    }
  });
});
