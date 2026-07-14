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

/// Minimum reconnect delay (seconds) after DNS / socket network failures.
@visibleForTesting
const kRealtimeNetworkErrorMinDelaySeconds = 5;

/// Maximum reconnect backoff (seconds).
@visibleForTesting
const kRealtimeMaxReconnectDelaySeconds = 60;

/// Suppress duplicate status logs within this window.
@visibleForTesting
const kRealtimeErrorLogThrottle = Duration(seconds: 10);

/// Whether [error] looks like a client network / DNS failure (not auth/ACL).
@visibleForTesting
bool isFlatmatesRealtimeNetworkError(Object? error) {
  if (error == null) return false;
  final message = error.toString().toLowerCase();
  const markers = [
    'failed host lookup',
    'socketexception',
    'nodename nor servname',
    'network is unreachable',
    'no route to host',
    'connection refused',
    'connection reset',
    'connection closed',
    'connection aborted',
    'websocketchannelexception',
    'clientexception',
  ];
  return markers.any(message.contains);
}

/// Next reconnect delay after a failure.
@visibleForTesting
int nextRealtimeReconnectDelaySeconds({
  required int currentDelaySeconds,
  required bool isNetworkError,
}) {
  final floor = isNetworkError
      ? kRealtimeNetworkErrorMinDelaySeconds
      : 1;
  final base = currentDelaySeconds < floor ? floor : currentDelaySeconds;
  return (base * 2).clamp(floor, kRealtimeMaxReconnectDelaySeconds);
}

/// Delay to wait before the next reconnect attempt.
@visibleForTesting
int realtimeReconnectWaitSeconds({
  required int currentDelaySeconds,
  required bool isNetworkError,
}) {
  final floor = isNetworkError
      ? kRealtimeNetworkErrorMinDelaySeconds
      : 1;
  return currentDelaySeconds < floor ? floor : currentDelaySeconds;
}

/// Supabase Realtime Broadcast subscriber for flatmates user channels.
///
/// Replaces the deprecated HTTP SSE endpoint (`/flatmates/sse`), which was
/// removed from the backend in favour of private Realtime channels.
///
/// Resilience:
/// - single-flight connect / reconnect (no stacked sockets on bootstrap thrash)
/// - longer backoff + throttled logs for DNS / host-lookup failures
/// - [setNetworkAvailable] pauses reconnects while offline and resumes once
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
  bool _connecting = false;
  bool _networkAvailable = true;
  DateTime? _lastErrorLogAt;
  String? _lastErrorSignature;
  bool _loggedDnsHint = false;

  /// Parsed event stream. Safe to access before [connect] is called.
  Stream<FlatmatesRealtimeEvent> get events =>
      (_controller ??= StreamController<FlatmatesRealtimeEvent>.broadcast())
          .stream;

  /// Whether the service believes the device has network.
  @visibleForTesting
  bool get isNetworkAvailable => _networkAvailable;

  /// Whether a subscribe attempt is in flight.
  @visibleForTesting
  bool get isConnecting => _connecting;

  /// Whether a reconnect timer is pending.
  @visibleForTesting
  bool get hasPendingReconnect => _reconnectTimer != null;

  /// Current backoff delay used for the next failure scheduling step.
  @visibleForTesting
  int get reconnectDelaySeconds => _reconnectDelaySeconds;

  /// Configured channel name, if any.
  @visibleForTesting
  String? get channelName => _channelName;

  /// Pause/resume based on device connectivity.
  ///
  /// When [available] is false: cancel reconnects, close the channel, keep
  /// channel config so a later online signal can resume.
  /// When true: open a connection if config is present and not intentionally
  /// disconnected.
  void setNetworkAvailable(bool available) {
    if (_disposed) return;

    final wasAvailable = _networkAvailable;
    _networkAvailable = available;

    if (!available) {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _connecting = false;
      _closeChannel();
      if (wasAvailable) {
        debugPrint('FlatmatesRealtimeService: paused (offline)');
      }
      return;
    }

    // Online: resume if we still have a target channel and are not logged out.
    if (_intentionalDisconnect ||
        _channelName == null ||
        _tokenRefresher == null) {
      return;
    }
    if (_subscribed || _connecting || _channel != null) return;

    if (!wasAvailable) {
      debugPrint('FlatmatesRealtimeService: resuming (online)');
      _reconnectDelaySeconds = 1;
      _openConnection();
      return;
    }

    // Connectivity re-confirmed while already "online": do not stack another
    // open on top of an in-flight backoff timer.
    if (_reconnectTimer != null) return;
    _openConnection();
  }

  /// Open (or reopen) the Realtime subscription for [channelName].
  ///
  /// Idempotent: if already subscribed, connecting, or reconnect-scheduled for
  /// the same channel, this is a no-op so bootstrap refreshes do not thrash.
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
        (_subscribed ||
            _channel != null ||
            _connecting ||
            _reconnectTimer != null);

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
    if (!_networkAvailable) {
      // Config stored; [setNetworkAvailable(true)] will open later.
      return;
    }
    _openConnection();
  }

  /// Gracefully tear down. No automatic reconnect.
  void disconnect() {
    _intentionalDisconnect = true;
    _subscribed = false;
    _connecting = false;
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
        _intentionalDisconnect ||
        !_networkAvailable) {
      return;
    }
    if (_connecting) return;

    _connecting = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _closeChannel();

    _tokenRefresher!()
        .then((token) {
          if (_disposed || _intentionalDisconnect || !_networkAvailable) {
            _connecting = false;
            return;
          }
          if (token == null) {
            // Token not ready yet (auth race / storage miss) — retry with backoff
            // instead of leaving the session permanently silent.
            _connecting = false;
            _logThrottled(
              'FlatmatesRealtimeService: access token null; scheduling reconnect',
            );
            _scheduleReconnect(isNetworkError: false);
            return;
          }
          unawaited(_subscribe(token));
        })
        .catchError((Object e) {
          _connecting = false;
          _logThrottled(
            'FlatmatesRealtimeService: token refresh failed: $e',
          );
          if (!_disposed &&
              !_intentionalDisconnect &&
              _networkAvailable) {
            _scheduleReconnect(
              isNetworkError: isFlatmatesRealtimeNetworkError(e),
            );
          }
        });
  }

  Future<void> _subscribe(String token) async {
    if (_disposed ||
        _intentionalDisconnect ||
        _channelName == null ||
        !_networkAvailable) {
      _connecting = false;
      return;
    }

    final client = Supabase.instance.client;
    try {
      await client.realtime.setAuth(token);
    } catch (e) {
      _connecting = false;
      _logThrottled('FlatmatesRealtimeService: setAuth failed: $e');
      if (!_disposed && !_intentionalDisconnect && _networkAvailable) {
        _scheduleReconnect(isNetworkError: isFlatmatesRealtimeNetworkError(e));
      }
      return;
    }

    if (_disposed || _intentionalDisconnect || !_networkAvailable) {
      _connecting = false;
      return;
    }

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
        _connecting = false;
        _reconnectDelaySeconds = 1;
        _loggedDnsHint = false;
        debugPrint('FlatmatesRealtimeService: subscribed to $_channelName');
        return;
      }

      if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut ||
          status == RealtimeSubscribeStatus.closed) {
        final networkError =
            isFlatmatesRealtimeNetworkError(error) ||
            status == RealtimeSubscribeStatus.timedOut;
        _logChannelStatus(status, error, networkError: networkError);
        _subscribed = false;
        _connecting = false;
        _closeChannel();
        if (!_disposed && !_intentionalDisconnect && _networkAvailable) {
          _scheduleReconnect(isNetworkError: networkError);
        }
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

  void _scheduleReconnect({required bool isNetworkError}) {
    if (_disposed || _intentionalDisconnect || !_networkAvailable) return;
    // Single-flight: do not reset an in-flight backoff timer (avoids storms
    // when bootstrap + status callbacks fire repeatedly during DNS failures).
    if (_reconnectTimer != null) return;

    final wait = realtimeReconnectWaitSeconds(
      currentDelaySeconds: _reconnectDelaySeconds,
      isNetworkError: isNetworkError,
    );
    _reconnectTimer = Timer(Duration(seconds: wait), () {
      _reconnectTimer = null;
      if (!_disposed &&
          !_intentionalDisconnect &&
          _networkAvailable &&
          _channelName != null &&
          _tokenRefresher != null) {
        _openConnection();
      }
    });
    _reconnectDelaySeconds = nextRealtimeReconnectDelaySeconds(
      currentDelaySeconds: wait,
      isNetworkError: isNetworkError,
    );
  }

  void _logChannelStatus(
    RealtimeSubscribeStatus status,
    Object? error, {
    required bool networkError,
  }) {
    final signature = '$status|${error ?? ''}';
    final now = DateTime.now();
    final throttled =
        _lastErrorSignature == signature &&
        _lastErrorLogAt != null &&
        now.difference(_lastErrorLogAt!) < kRealtimeErrorLogThrottle;
    if (!throttled) {
      _lastErrorSignature = signature;
      _lastErrorLogAt = now;
      debugPrint(
        'FlatmatesRealtimeService: channel status=$status error=$error',
      );
    }

    if (networkError && !_loggedDnsHint) {
      _loggedDnsHint = true;
      final host = _hostFromError(error);
      if (host != null) {
        debugPrint(
          'FlatmatesRealtimeService: DNS/network failure resolving $host '
          '— retrying with backoff (check device network / simulator DNS)',
        );
      } else {
        debugPrint(
          'FlatmatesRealtimeService: network failure on Realtime socket '
          '— retrying with backoff',
        );
      }
    }
  }

  void _logThrottled(String message) {
    final now = DateTime.now();
    final throttled =
        _lastErrorSignature == message &&
        _lastErrorLogAt != null &&
        now.difference(_lastErrorLogAt!) < kRealtimeErrorLogThrottle;
    if (throttled) return;
    _lastErrorSignature = message;
    _lastErrorLogAt = now;
    debugPrint(message);
  }

  static String? _hostFromError(Object? error) {
    if (error == null) return null;
    final match = RegExp(
      r"Failed host lookup: '([^']+)'",
      caseSensitive: false,
    ).firstMatch(error.toString());
    return match?.group(1);
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
