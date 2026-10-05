import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import 'package:flatmates_app/core/network/interceptors/auth_interceptor.dart';
import 'package:flatmates_app/core/network/auth_token_provider.dart';

/// A configurable fake [AuthTokenProvider] for testing.
class _FakeTokenProvider implements AuthTokenProvider {
  _FakeTokenProvider({String? token}) : _token = token;

  String? _token;
  bool clearSessionCalled = false;

  void setToken(String? token) => _token = token;

  @override
  Future<String?> getAccessToken({String? rejectedToken}) async => _token;

  @override
  Future<void> clearSession() async {
    clearSessionCalled = true;
    _token = null;
  }
}

void main() {
  group('AuthInterceptor.onRequest', () {
    test('attaches Bearer token to requests', () async {
      final tokenProvider = _FakeTokenProvider(token: 'test-token-123');
      final dio = Dio();

      final options = RequestOptions(path: '/test');
      final handler = _RecordingRequestHandler();
      final interceptor = AuthInterceptor(
        tokenProvider: tokenProvider,
        dio: dio,
      );
      await interceptor.onRequest(options, handler);

      expect(handler.nextCalled, isTrue);
      expect(options.headers['Authorization'], 'Bearer test-token-123');
    });

    test('does not attach Authorization header when token is null', () async {
      final tokenProvider = _FakeTokenProvider();
      final dio = Dio();

      final options = RequestOptions(path: '/test');
      final handler = _RecordingRequestHandler();
      final interceptor = AuthInterceptor(
        tokenProvider: tokenProvider,
        dio: dio,
      );
      await interceptor.onRequest(options, handler);

      expect(handler.nextCalled, isTrue);
      expect(options.headers['Authorization'], isNull);
    });

    test('does not attach Authorization header when token is empty', () async {
      final tokenProvider = _FakeTokenProvider(token: '');
      final dio = Dio();

      final options = RequestOptions(path: '/test');
      final handler = _RecordingRequestHandler();
      final interceptor = AuthInterceptor(
        tokenProvider: tokenProvider,
        dio: dio,
      );
      await interceptor.onRequest(options, handler);

      expect(handler.nextCalled, isTrue);
      expect(options.headers['Authorization'], isNull);
    });
  });

  group('AuthInterceptor.onError', () {
    test('clears session when token is null after 401', () async {
      final tokenProvider = _FakeTokenProvider();
      final dio = Dio();

      final requestOptions = RequestOptions(path: '/test');
      final exception = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );
      final handler = _RecordingErrorHandler();
      final interceptor = AuthInterceptor(
        tokenProvider: tokenProvider,
        dio: dio,
      );
      await interceptor.onError(exception, handler);

      expect(tokenProvider.clearSessionCalled, isTrue);
      expect(handler.nextCalled, isTrue);
    });

    test('a throwing clearSession still releases the queue', () async {
      final tokenProvider = _ThrowingClearTokenProvider();
      final dio = Dio();
      final interceptor = AuthInterceptor(
        tokenProvider: tokenProvider,
        dio: dio,
      );

      final first = _RecordingErrorHandler();
      final queued = _RecordingErrorHandler();
      final a = interceptor.onError(_unauthorized('/a', 'old'), first);
      final b = interceptor.onError(_unauthorized('/b', 'old'), queued);

      // Bounded on purpose: if the queue is never drained, this times out
      // instead of hanging the suite.
      await expectLater(
        Future.wait([a, b]).timeout(const Duration(seconds: 5)),
        completes,
      );

      // This request still surfaces the 401...
      expect(first.nextCalled, isTrue);
      expect(first.capturedError?.response?.statusCode, 401);
      // ...and the queued request is released with the same error rather than
      // left waiting on a completer nobody completes.
      expect(queued.nextCalled, isTrue);
      expect(queued.capturedError?.response?.statusCode, 401);
      expect(
        queued.capturedError?.error,
        'Session expired. Please sign in again.',
      );
      expect(tokenProvider.clearSessionCalled, isTrue);
    });

    test('does not retry when _retried is already true', () async {
      final tokenProvider = _FakeTokenProvider(token: 'new-token');
      final dio = Dio();

      final requestOptions = RequestOptions(path: '/test');
      requestOptions.extra['_retried'] = true;
      final exception = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );
      final handler = _RecordingErrorHandler();
      final interceptor = AuthInterceptor(
        tokenProvider: tokenProvider,
        dio: dio,
      );
      await interceptor.onError(exception, handler);

      // Should forward the error without retrying.
      expect(handler.nextCalled, isTrue);
      expect(tokenProvider.clearSessionCalled, isFalse);
    });

    test('forwards non-401 errors without clearing session', () async {
      final tokenProvider = _FakeTokenProvider(token: 'valid-token');
      final dio = Dio();

      final requestOptions = RequestOptions(path: '/test');
      final exception = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 500),
      );
      final handler = _RecordingErrorHandler();
      final interceptor = AuthInterceptor(
        tokenProvider: tokenProvider,
        dio: dio,
      );
      await interceptor.onError(exception, handler);

      expect(tokenProvider.clearSessionCalled, isFalse);
      expect(handler.nextCalled, isTrue);
    });

    test(
      'passes the rejected token so the provider can force a refresh',
      () async {
        final tokenProvider = _GatedTokenProvider('new-token');
        final dio = Dio()..httpClientAdapter = _PathStatusAdapter({'/a': 200});
        final interceptor = AuthInterceptor(
          tokenProvider: tokenProvider,
          dio: dio,
        );

        final handler = _RecordingErrorHandler();
        final done = interceptor.onError(
          _unauthorized('/a', 'old-token'),
          handler,
        );
        tokenProvider.release();
        await done;

        expect(tokenProvider.rejected, 'old-token');
        expect(handler.resolved?.statusCode, 200);
      },
    );

    test('one failed retry does not fail queued requests as expired', () async {
      final tokenProvider = _GatedTokenProvider('new-token');
      final dio = Dio()
        ..httpClientAdapter = _PathStatusAdapter({'/a': 500, '/b': 200});
      final interceptor = AuthInterceptor(
        tokenProvider: tokenProvider,
        dio: dio,
      );

      final first = _RecordingErrorHandler();
      final queued = _RecordingErrorHandler();
      final a = interceptor.onError(_unauthorized('/a', 'old'), first);
      final b = interceptor.onError(_unauthorized('/b', 'old'), queued);
      tokenProvider.release();
      await Future.wait([a, b]);

      expect(first.capturedError?.response?.statusCode, 500);
      expect(queued.resolved?.statusCode, 200);
      expect(tokenProvider.clearSessionCalled, isFalse);
    });

    test('a non-transient refresh failure does not wedge later 401s', () async {
      final tokenProvider = _ThrowingTokenProvider();
      final dio = Dio()..httpClientAdapter = _PathStatusAdapter({'/b': 200});
      final interceptor = AuthInterceptor(
        tokenProvider: tokenProvider,
        dio: dio,
      );

      final first = _RecordingErrorHandler();
      final queued = _RecordingErrorHandler();
      final a = interceptor.onError(_unauthorized('/a', 'old'), first);
      final b = interceptor.onError(_unauthorized('/b', 'old'), queued);
      await Future.wait([a, b]);

      // The failed refresh is forwarded, the queued request is released, and
      // no second refresh was started for it.
      expect(first.nextCalled, isTrue);
      expect(first.capturedError?.error, isA<StateError>());
      expect(queued.nextCalled, isTrue);
      expect(queued.capturedError?.error, isA<StateError>());
      expect(tokenProvider.calls, 1);
      expect(tokenProvider.clearSessionCalled, isFalse);

      // The refresh gate is released: the next 401 refreshes and retries.
      tokenProvider.throwing = false;
      final later = _RecordingErrorHandler();
      await interceptor.onError(_unauthorized('/b', 'old'), later);

      expect(tokenProvider.calls, 2);
      expect(later.resolved?.statusCode, 200);
    });

    test('does not retry with the token the server rejected', () async {
      final tokenProvider = _FakeTokenProvider(token: 'old-token');
      final dio = Dio()..httpClientAdapter = _PathStatusAdapter({'/a': 200});
      final interceptor = AuthInterceptor(
        tokenProvider: tokenProvider,
        dio: dio,
      );

      final handler = _RecordingErrorHandler();
      final exception = _unauthorized('/a', 'old-token');
      await interceptor.onError(exception, handler);

      // No second round trip: the original 401 is forwarded untouched.
      expect(handler.resolved, isNull);
      expect(handler.capturedError, same(exception));
      expect(tokenProvider.clearSessionCalled, isFalse);
    });

    test('a same-token refresh fails the queue without a retry', () async {
      final tokenProvider = _GatedTokenProvider('old');
      final dio = Dio()
        ..httpClientAdapter = _PathStatusAdapter({'/a': 200, '/b': 200});
      final interceptor = AuthInterceptor(
        tokenProvider: tokenProvider,
        dio: dio,
      );

      final first = _RecordingErrorHandler();
      final queued = _RecordingErrorHandler();
      final a = interceptor.onError(_unauthorized('/a', 'old'), first);
      final b = interceptor.onError(_unauthorized('/b', 'old'), queued);
      tokenProvider.release();
      await Future.wait([a, b]);

      expect(first.resolved, isNull);
      expect(first.capturedError?.response?.statusCode, 401);
      expect(queued.resolved, isNull);
      expect(queued.capturedError?.response?.statusCode, 401);
    });
  });
}

DioException _unauthorized(String path, String token) {
  final options = RequestOptions(
    path: path,
    headers: {'Authorization': 'Bearer $token'},
  );
  return DioException(
    type: DioExceptionType.badResponse,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: 401),
  );
}

/// Holds token refresh open until [release], so a second 401 can queue.
class _GatedTokenProvider implements AuthTokenProvider {
  _GatedTokenProvider(this._token);

  final String _token;
  final _gate = Completer<void>();
  String? rejected;
  bool clearSessionCalled = false;

  void release() => _gate.complete();

  @override
  Future<String?> getAccessToken({String? rejectedToken}) async {
    rejected = rejectedToken;
    await _gate.future;
    return _token;
  }

  @override
  Future<void> clearSession() async => clearSessionCalled = true;
}

/// Reports the session as gone (no token) but throws when the session is
/// cleared — the keychain delete can fail, for example iOS error -25308.
class _ThrowingClearTokenProvider implements AuthTokenProvider {
  bool clearSessionCalled = false;

  @override
  Future<String?> getAccessToken({String? rejectedToken}) async => null;

  @override
  Future<void> clearSession() async {
    clearSessionCalled = true;
    throw StateError('keychain unavailable');
  }
}

/// Throws a non-transient error while [throwing] is true, then hands out a
/// fresh token. Counts attempts so a test can prove the refresh gate was
/// released after a failure.
class _ThrowingTokenProvider implements AuthTokenProvider {
  bool throwing = true;
  int calls = 0;
  bool clearSessionCalled = false;

  @override
  Future<String?> getAccessToken({String? rejectedToken}) async {
    calls++;
    if (throwing) throw StateError('session storage unavailable');
    return 'new-token';
  }

  @override
  Future<void> clearSession() async => clearSessionCalled = true;
}

/// Answers each request path with a fixed status code.
class _PathStatusAdapter implements HttpClientAdapter {
  _PathStatusAdapter(this._statusByPath);

  final Map<String, int> _statusByPath;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{}',
    _statusByPath[options.path] ?? 404,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

/// A recording [RequestInterceptorHandler] for testing that does not propagate
/// to the real handler (which would throw outside a real Dio request cycle).
class _RecordingRequestHandler extends RequestInterceptorHandler {
  bool nextCalled = false;
  RequestOptions? capturedOptions;

  @override
  void next(RequestOptions options) {
    nextCalled = true;
    capturedOptions = options;
  }
}

/// A recording [ErrorInterceptorHandler] for testing that does not propagate
/// to the real handler (which would throw outside a real Dio request cycle).
class _RecordingErrorHandler extends ErrorInterceptorHandler {
  bool nextCalled = false;
  DioException? capturedError;
  Response<dynamic>? resolved;

  @override
  void resolve(Response<dynamic> response) {
    resolved = response;
  }

  @override
  void next(DioException err) {
    nextCalled = true;
    capturedError = err;
  }
}
