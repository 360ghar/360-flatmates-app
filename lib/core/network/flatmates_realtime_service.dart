import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A single flatmates realtime event (broadcast or legacy SSE-shaped).
class FlatmatesRealtimeEvent {
  const FlatmatesRealtimeEvent({required this.type, required this.data});

  final String type;
  final Map<String, dynamic> data;

  @override
  String toString() => 'FlatmatesRealtimeEvent(type: $type, data: $data)';
}

/// Callback that returns a fresh access token before (re)subscribe.
typedef TokenRefresher = Future<String?> Function();

/// Default broadcast events published by the backend realtime bus.
const List<String> kFlatmatesRealtimeEvents = [
  'new_match',
  'new_message',
  'conversation_updated',
  'visit_updated',
  'listing_status_changed',
  'new_notification',
];

/// Supabase Realtime Broadcast subscriber for flatmates user channels.
///
/// Replaces the deprecated HTTP SSE endpoint (`/flatmates/sse`), which was
/// removed from the backend in favour of private Realtime channels.
class FlatmatesRealtimeService {
  StreamController<FlatmatesRealtimeEvent>? _controller;
  RealtimeChannel? _channel;
  Timer? _reconnectTimer;
  TokenRefresher? _tokenRefresher;
  String? _channelName;
  bool _private = true;
  List<String> _events = List<String>.from(kFlatmatesRealtimeEvents);
  int _reconnectDelaySeconds = 1;
  bool _disposed = false;
  bool _intentionalDisconnect = false;
  bool _subscribed = false;

  /// Parsed event stream. Safe to access before [connect] is called.
  Stream<FlatmatesRealtimeEvent> get events =>
      (_controller ??= StreamController<FlatmatesRealtimeEvent>.broadcast())
          .stream;

  /// Open (or reopen) the Realtime subscription for [channelName].
  ///
  /// Idempotent: if already subscribed to the same channel, this is a no-op
  /// so bootstrap refreshes do not thrash the socket.
  void connect({
    required String channelName,
    required TokenRefresher tokenRefresher,
    bool privateChannel = true,
    List<String>? events,
  }) {
    if (_disposed) return;

    final sameChannel =
        _channelName == channelName &&
        _private == privateChannel &&
        !_intentionalDisconnect &&
        (_subscribed || _channel != null);

    _channelName = channelName;
    _tokenRefresher = tokenRefresher;
    _private = privateChannel;
    if (events != null && events.isNotEmpty) {
      _events = List<String>.from(events);
    }
    _intentionalDisconnect = false;
    _ensureController();

    if (sameChannel) {
      return;
    }
    _openConnection();
  }

  /// Gracefully tear down. No automatic reconnect.
  void disconnect() {
    _intentionalDisconnect = true;
    _subscribed = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _closeChannel();
  }

  /// Permanently shut down. Cannot be reused after calling this.
  void dispose() {
    _disposed = true;
    disconnect();
    _controller?.close();
    _controller = null;
  }

  void _ensureController() {
    _controller ??= StreamController<FlatmatesRealtimeEvent>.broadcast();
  }

  void _openConnection() {
    if (_disposed ||
        _channelName == null ||
        _tokenRefresher == null ||
        _intentionalDisconnect) {
      return;
    }
    _closeChannel();

    _tokenRefresher!()
        .then((token) {
          if (_disposed || _intentionalDisconnect) return;
          if (token == null) {
            // Token not ready yet (auth race / storage miss) — retry with backoff
            // instead of leaving the session permanently silent.
            debugPrint(
              'FlatmatesRealtimeService: access token null; scheduling reconnect',
            );
            _scheduleReconnect();
            return;
          }
          unawaited(_subscribe(token));
        })
        .catchError((Object e) {
          debugPrint('FlatmatesRealtimeService: token refresh failed: $e');
          if (!_disposed && !_intentionalDisconnect) _scheduleReconnect();
        });
  }

  Future<void> _subscribe(String token) async {
    if (_disposed || _intentionalDisconnect || _channelName == null) return;

    final client = Supabase.instance.client;
    try {
      await client.realtime.setAuth(token);
    } catch (e) {
      debugPrint('FlatmatesRealtimeService: setAuth failed: $e');
      if (!_disposed && !_intentionalDisconnect) _scheduleReconnect();
      return;
    }

    if (_disposed || _intentionalDisconnect) return;

    final channel = client.channel(
      _channelName!,
      opts: RealtimeChannelConfig(private: _private),
    );
    _channel = channel;

    for (final eventName in _events) {
      channel.onBroadcast(
        event: eventName,
        callback: (payload) {
          if (_disposed || _intentionalDisconnect) return;
          final data = _normalizeBroadcastData(payload);
          final controller = _controller;
          if (controller == null || controller.isClosed) return;
          controller.add(FlatmatesRealtimeEvent(type: eventName, data: data));
        },
      );
    }

    channel.subscribe((status, [error]) {
      if (_disposed || _intentionalDisconnect || _channel != channel) return;

      if (status == RealtimeSubscribeStatus.subscribed) {
        _subscribed = true;
        _reconnectDelaySeconds = 1;
        debugPrint('FlatmatesRealtimeService: subscribed to $_channelName');
        return;
      }

      if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut ||
          status == RealtimeSubscribeStatus.closed) {
        debugPrint(
          'FlatmatesRealtimeService: channel status=$status error=$error',
        );
        _subscribed = false;
        _closeChannel();
        if (!_disposed && !_intentionalDisconnect) _scheduleReconnect();
      }
    });
  }

  void _closeChannel() {
    final channel = _channel;
    _channel = null;
    _subscribed = false;
    if (channel == null) return;
    try {
      unawaited(Supabase.instance.client.removeChannel(channel));
    } catch (e) {
      debugPrint('FlatmatesRealtimeService: removeChannel failed: $e');
    }
  }

  void _scheduleReconnect() {
    if (_disposed || _intentionalDisconnect) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _reconnectDelaySeconds), () {
      if (!_disposed &&
          !_intentionalDisconnect &&
          _channelName != null &&
          _tokenRefresher != null) {
        _openConnection();
      }
    });
    _reconnectDelaySeconds = (_reconnectDelaySeconds * 2).clamp(1, 30);
  }
}

/// Backend publishes `{ type, data, sent_at }` nested under broadcast payload.
Map<String, dynamic> normalizeFlatmatesBroadcastData(
  Map<String, dynamic> payload,
) {
  return _normalizeBroadcastData(payload);
}

Map<String, dynamic> _normalizeBroadcastData(Map<String, dynamic> payload) {
  final inner = payload['payload'];
  final Map<String, dynamic> body;
  if (inner is Map) {
    body = Map<String, dynamic>.from(inner);
  } else {
    body = payload;
  }
  final data = body['data'];
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  return body;
}
