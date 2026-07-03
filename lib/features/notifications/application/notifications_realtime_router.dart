import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/flatmates_realtime_providers.dart';
import '../../../core/network/flatmates_realtime_service.dart';
import '../notifications_repository.dart';

final notificationsRealtimeRouterProvider = Provider<void>((ref) {
  ref.listen(flatmatesRealtimeEventProvider, (previous, next) {
    final event = next.valueOrNull;
    if (event == null) return;
    routeNotificationsRealtimeEvent(ref, event);
  });
});

void routeNotificationsRealtimeEvent(Ref ref, FlatmatesRealtimeEvent event) {
  if (event.type == 'new_notification') {
    ref.invalidate(notificationsProvider);
  }
}
