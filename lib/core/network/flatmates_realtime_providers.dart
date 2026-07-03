import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'flatmates_realtime_service.dart';

final flatmatesRealtimeServiceProvider = Provider<FlatmatesRealtimeService>((
  ref,
) {
  final service = FlatmatesRealtimeService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

final flatmatesRealtimeEventProvider = StreamProvider<FlatmatesRealtimeEvent>((
  ref,
) {
  return ref.watch(flatmatesRealtimeServiceProvider).events;
});
