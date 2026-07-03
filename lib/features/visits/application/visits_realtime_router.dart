import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/flatmates_realtime_providers.dart';
import '../../../core/network/flatmates_realtime_service.dart';
import '../visits_repository.dart';

final visitsRealtimeRouterProvider = Provider<void>((ref) {
  ref.listen(flatmatesRealtimeEventProvider, (previous, next) {
    final event = next.valueOrNull;
    if (event == null) return;
    routeVisitsRealtimeEvent(ref, event);
  });
});

void routeVisitsRealtimeEvent(Ref ref, FlatmatesRealtimeEvent event) {
  if (event.type == 'visit_updated') {
    ref.invalidate(visitsProvider);
  }
}
