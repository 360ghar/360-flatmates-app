import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/chats/application/chats_realtime_router.dart';
import '../features/notifications/application/notifications_realtime_router.dart';
import '../features/visits/application/visits_realtime_router.dart';

final flatmatesRealtimeRoutersProvider = Provider<void>((ref) {
  ref.watch(chatsRealtimeRouterProvider);
  ref.watch(notificationsRealtimeRouterProvider);
  ref.watch(visitsRealtimeRouterProvider);
});
