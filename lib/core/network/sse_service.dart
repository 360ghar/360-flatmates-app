import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A single parsed Server-Sent Event.
class SseEvent {
  const SseEvent({required this.type, required this.data});

  final String type;
  final Map<String, dynamic> data;

  @override
  String toString() => 'SseEvent(type: $type, data: $data)';
}

/// Callback that returns a fresh access token. Called before each connection
/// attempt (initial + reconnects) so the JWT is never stale.
typedef TokenRefresher = Future<String?> Function();

/// Manages a long-lived SSE connection to the flatmates events endpoint.
///
/// Handles connection, line-by-line SSE parsing, automatic reconnection with
/// exponential backoff, and graceful disconnect on logout.
class SseService {
  StreamController<SseEvent>? _controller;
  Timer? _reconnectTimer;
  String? _baseUrl;
  TokenRefresher? _tokenRefresher;
  int _reconnectDelaySeconds = 1;
  bool _disposed = false;
  bool _intentionalDisconnect = false;

  /// The parsed event stream. Safe to access before [connect] is called.
  Stream<SseEvent> get events =>
      (_controller ??= StreamController<SseEvent>.broadcast()).stream;

  /// Open (or reopen) the SSE connection.
  ///
  /// [tokenRefresher] is called before every connection attempt to get a
  /// fresh JWT. This avoids reconnecting with an expired token.
  void connect(String baseUrl, TokenRefresher tokenRefresher) {
    if (_disposed) return;
    _baseUrl = baseUrl;
    _tokenRefresher = tokenRefresher;
    _intentionalDisconnect = false;
    _ensureController();
    _openConnection();
  }

  /// Gracefully tear down the connection. No automatic reconnect.
  void disconnect() {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    // Close the HttpClient if one is active.
    _closeConnection();
  }

  /// Permanently shut down. Cannot be reused after calling this.
  void dispose() {
    _disposed = true;
    disconnect();
    _controller?.close();
    _controller = null;
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _ensureController() {
    _controller ??= StreamController<SseEvent>.broadcast();
  }

  void _openConnection() {
    if (_disposed || _baseUrl == null || _tokenRefresher == null) return;
    _closeConnection();

    // Fire-and-forget: get token, then open the connection.
    _tokenRefresher!().then((token) {
      if (_disposed || _intentionalDisconnect || token == null) return;
      _startStream(token);
    }).catchError((_) {
      // Token refresh failed — schedule reconnect
      if (!_disposed && !_intentionalDisconnect) _scheduleReconnect();
    });
  }

  void _startStream(String token) {
    final client = HttpClient()..idleTimeout = const Duration(minutes: 10);

    _doConnect(client, token).then((_) {
      // Stream ended normally
      client.close(force: true);
      if (!_disposed && !_intentionalDisconnect) _scheduleReconnect();
    }).catchError((_) {
      client.close(force: true);
      if (!_disposed && !_intentionalDisconnect) _scheduleReconnect();
    });
  }

  Future<void> _doConnect(HttpClient client, String token) async {
    final uri = Uri.parse('$_baseUrl/flatmates/sse');
    final request = await client.getUrl(uri);
    request.headers.set('Accept', 'text/event-stream');
    request.headers.set('Authorization', 'Bearer $token');
    request.headers.set('Cache-Control', 'no-cache');

    final response = await request.close();

    if (response.statusCode != 200) {
      // Auth failure or server error — don't parse as SSE.
      // Drain the response body to free resources.
      await response.drain<void>();
      if (response.statusCode == 401 || response.statusCode == 403) {
        // Auth error — clear stale token so next reconnect fetches a new one.
        // But don't give up entirely; the token refresher will try again.
      }
      return; // triggers reconnect via the .then() in _startStream
    }

    _reconnectDelaySeconds = 1; // reset backoff on successful connect

    String? eventType;
    final buffer = StringBuffer();

    await for (final chunk
        in response.transform(utf8.decoder).transform(const LineSplitter())) {
      if (_disposed || _intentionalDisconnect) break;

      if (chunk.isEmpty) {
        // Blank line → dispatch accumulated event
        final data = buffer.toString().trim();
        if (data.isNotEmpty &&
            _controller != null &&
            !_controller!.isClosed) {
          try {
            final parsed = jsonDecode(data) as Map<String, dynamic>;
            _controller!.add(SseEvent(
              type: eventType ?? 'message',
              data: parsed,
            ));
          } catch (_) {
            // Ignore malformed JSON
          }
        }
        eventType = null;
        buffer.clear();
        continue;
      }

      if (chunk.startsWith(':')) {
        // SSE comment (keepalive) — ignore
        continue;
      }

      if (chunk.startsWith('event:')) {
        eventType = chunk.substring(6).trim();
      } else if (chunk.startsWith('data:')) {
        // Handles both "data:value" and "data: value" via trim.
        buffer.writeln(chunk.substring(5).trim());
      }
    }
  }

  void _closeConnection() {
    // HttpClient is owned by each _startStream call and closed there.
    // Nothing to close here — this method is kept for future use.
  }

  void _scheduleReconnect() {
    if (_disposed || _intentionalDisconnect) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _reconnectDelaySeconds), () {
      if (!_disposed &&
          !_intentionalDisconnect &&
          _baseUrl != null &&
          _tokenRefresher != null) {
        _openConnection();
      }
    });
    _reconnectDelaySeconds = (_reconnectDelaySeconds * 2).clamp(1, 30);
  }
}
