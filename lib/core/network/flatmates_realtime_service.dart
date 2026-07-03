import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FlatmatesRealtimeEvent {
  const FlatmatesRealtimeEvent({required this.type, required this.data});

  factory FlatmatesRealtimeEvent.fromBroadcast({
    required String fallbackType,
    required Map<String, dynamic> payload,
  }) {
    final data = payload['data'];
    return FlatmatesRealtimeEvent(
      type: payload['type']?.toString() ?? fallbackType,
      data: data is Map
          ? Map<String, dynamic>.from(data)
          : Map<String, dynamic>.from(payload),
    );
  }

  final String type;
  final Map<String, dynamic> data;

  @override
  String toString() => 'FlatmatesRealtimeEvent(type: $type, data: $data)';
}

typedef TokenRefresher = Future<String?> Function();

const _tokenRefreshTimeout = Duration(seconds: 10);

class _RealtimeSubscriptionConfig {
  const _RealtimeSubscriptionConfig({
    required this.channel,
    required this.private,
    required this.events,
  });

  final String channel;
  final bool private;
  final List<String> events;

  bool matches(_RealtimeSubscriptionConfig other) {
    return channel == other.channel &&
        private == other.private &&
        listEquals(events, other.events);
  }
}

class FlatmatesRealtimeService {
  FlatmatesRealtimeService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final StreamController<FlatmatesRealtimeEvent> _controller =
      StreamController<FlatmatesRealtimeEvent>.broadcast();

  RealtimeChannel? _channel;
  _RealtimeSubscriptionConfig? _config;
  TokenRefresher? _tokenRefresher;
  Timer? _reconnectTimer;
  String? _channelName;
  var _connecting = false;
  var _subscribed = false;
  var _intentionalDisconnect = false;
  var _disposed = false;
  var _reconnectDelaySeconds = 1;
  var _requestVersion = 0;

  Stream<FlatmatesRealtimeEvent> get events => _controller.stream;

  void connect({
    required String channel,
    required bool private,
    required List<String> events,
    required TokenRefresher tokenRefresher,
  }) {
    if (_disposed || channel.isEmpty) {
      return;
    }
    final nextConfig = _RealtimeSubscriptionConfig(
      channel: channel,
      private: private,
      events: List.unmodifiable(events),
    );
    final configChanged = _config?.matches(nextConfig) != true;
    _config = nextConfig;
    _tokenRefresher = tokenRefresher;
    _intentionalDisconnect = false;

    if (configChanged) {
      _requestVersion++;
    }

    if (!configChanged && _channelName == channel && _subscribed) {
      return;
    }
    if (_connecting) {
      return;
    }

    unawaited(_open(_requestVersion));
  }

  Future<void> disconnect() async {
    _requestVersion++;
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _removeChannel();
  }

  Future<void> dispose() async {
    _disposed = true;
    await disconnect();
    await _controller.close();
  }

  Future<void> _open(int requestVersion) async {
    if (_disposed || _connecting || _intentionalDisconnect) return;
    final config = _config;
    final tokenRefresher = _tokenRefresher;
    if (config == null || tokenRefresher == null) return;

    _connecting = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    try {
      await _removeChannel();
      if (!_isCurrentAttempt(requestVersion, config)) return;

      final token = await tokenRefresher().timeout(_tokenRefreshTimeout);
      if (!_isCurrentAttempt(requestVersion, config)) return;
      if (token == null || token.isEmpty) {
        _scheduleReconnect();
        return;
      }

      await _client.realtime.setAuth(token);
      if (!_isCurrentAttempt(requestVersion, config)) return;

      final channel = _client.channel(
        config.channel,
        opts: RealtimeChannelConfig(private: config.private),
      );
      final events = config.events.isEmpty
          ? const [
              'new_match',
              'new_message',
              'conversation_updated',
              'visit_updated',
              'listing_status_changed',
              'new_notification',
            ]
          : config.events;
      for (final eventName in events) {
        channel.onBroadcast(
          event: eventName,
          callback: (payload) {
            if (_disposed || _intentionalDisconnect || _controller.isClosed) {
              return;
            }
            _controller.add(
              FlatmatesRealtimeEvent.fromBroadcast(
                fallbackType: eventName,
                payload: payload,
              ),
            );
          },
        );
      }
      _channel = channel;
      _channelName = config.channel;
      channel.subscribe((status, [error]) {
        if (_disposed || _intentionalDisconnect) return;
        if (!identical(_channel, channel)) return;
        switch (status) {
          case RealtimeSubscribeStatus.subscribed:
            _subscribed = true;
            _reconnectDelaySeconds = 1;
          case RealtimeSubscribeStatus.channelError:
          case RealtimeSubscribeStatus.closed:
          case RealtimeSubscribeStatus.timedOut:
            _subscribed = false;
            debugPrint(
              'FlatmatesRealtimeService: subscribe status=$status error=$error',
            );
            _scheduleReconnect();
        }
      });
    } catch (e) {
      if (_isCurrentAttempt(requestVersion, config)) {
        debugPrint('FlatmatesRealtimeService: connect failed: $e');
        _scheduleReconnect();
      }
    } finally {
      _connecting = false;
      if (!_disposed &&
          !_intentionalDisconnect &&
          requestVersion != _requestVersion) {
        unawaited(_open(_requestVersion));
      }
    }
  }

  Future<void> _removeChannel() async {
    final channel = _channel;
    _channel = null;
    _channelName = null;
    _subscribed = false;
    if (channel == null) return;
    try {
      await _client.removeChannel(channel);
    } catch (e) {
      debugPrint('FlatmatesRealtimeService: removeChannel failed: $e');
    }
  }

  void _scheduleReconnect() {
    if (_disposed || _intentionalDisconnect || _reconnectTimer != null) return;
    _reconnectTimer = Timer(Duration(seconds: _reconnectDelaySeconds), () {
      _reconnectTimer = null;
      unawaited(_open(_requestVersion));
    });
    _reconnectDelaySeconds = (_reconnectDelaySeconds * 2).clamp(1, 30).toInt();
  }

  bool _isCurrentAttempt(
    int requestVersion,
    _RealtimeSubscriptionConfig config,
  ) {
    final currentConfig = _config;
    return !_disposed &&
        !_intentionalDisconnect &&
        requestVersion == _requestVersion &&
        currentConfig != null &&
        currentConfig.matches(config);
  }
}
