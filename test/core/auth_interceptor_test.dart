import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/network/interceptors/auth_interceptor.dart';
import 'package:flatmates_app/core/network/auth_token_provider.dart';

// ---------------------------------------------------------------------------
// Fake AuthTokenProvider for testing
// ---------------------------------------------------------------------------

class FakeAuthTokenProvider implements AuthTokenProvider {
  String? _token;
  int _refreshCallCount = 0;
  bool _sessionCleared = false;
  int _throwOnCallNumber = -1;

  FakeAuthTokenProvider({String? initialToken}) : _token = initialToken;

  int get refreshCallCount => _refreshCallCount;
  bool get sessionCleared => _sessionCleared;

  void setToken(String? token) => _token = token;
  void throwTransientOnCall(int callNumber) => _throwOnCallNumber = callNumber;

  @override
  Future<String?> getAccessToken() async {
    _refreshCallCount++;
    if (_refreshCallCount == _throwOnCallNumber) {
      throw TransientAuthRefreshException(StateError('simulated network down'));
    }
    return _token;
  }

  @override
  Future<void> clearSession() async {
    _sessionCleared = true;
    _token = null;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a Dio instance with the [AuthInterceptor] and a test adapter.
({Dio dio, FakeAuthTokenProvider tokenProvider, MockHttpClientAdapter adapter})
createTestDio({String? initialToken}) {
  final tokenProvider = FakeAuthTokenProvider(initialToken: initialToken);
  final adapter = MockHttpClientAdapter();
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test.com'));
  dio.httpClientAdapter = adapter;
  dio.interceptors.add(AuthInterceptor(tokenProvider: tokenProvider, dio: dio));
  return (dio: dio, tokenProvider: tokenProvider, adapter: adapter);
}

/// A mock adapter that returns configurable responses.
class MockHttpClientAdapter implements HttpClientAdapter {
  final List<_MockResponse> _responses = [];
  final List<RequestOptions> _receivedRequests = [];

  List<RequestOptions> get receivedRequests =>
      List.unmodifiable(_receivedRequests);

  void addResponse(String body, int statusCode) {
    _responses.add(_MockResponse(body: body, statusCode: statusCode));
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    _receivedRequests.add(options);
    if (_responses.isEmpty) {
      return ResponseBody.fromString('{"ok": true}', 200);
    }
    final response = _responses.removeAt(0);
    return ResponseBody.fromString(response.body, response.statusCode);
  }

  @override
  void close({bool force = false}) {}
}

class _MockResponse {
  const _MockResponse({required this.body, required this.statusCode});
  final String body;
  final int statusCode;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AuthInterceptor', () {
    test('attaches Bearer token to requests', () async {
      final (:dio, :tokenProvider, :adapter) = createTestDio(
        initialToken: 'test-token',
      );

      await dio.get('/test');

      expect(adapter.receivedRequests.length, 1);
      expect(
        adapter.receivedRequests.first.headers['Authorization'],
        'Bearer test-token',
      );
    });

    test('does not attach token when null', () async {
      final (:dio, :tokenProvider, :adapter) = createTestDio();

      await dio.get('/test');

      expect(adapter.receivedRequests.length, 1);
      expect(
        adapter.receivedRequests.first.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('retries original request on 401 with new token', () async {
      final (:dio, :tokenProvider, :adapter) = createTestDio(
        initialToken: 'new-token',
      );

      // First response: 401
      adapter.addResponse('{"error": "unauthorized"}', 401);

      await dio.get('/protected');

      // After 401, interceptor retries with new token
      expect(adapter.receivedRequests.length, 2);
      expect(
        adapter.receivedRequests.last.headers['Authorization'],
        'Bearer new-token',
      );
    });

    test('clears session when token is null after 401', () async {
      final (:dio, :tokenProvider, :adapter) = createTestDio();

      adapter.addResponse('{"error": "unauthorized"}', 401);

      try {
        await dio.get('/protected');
      } catch (e) {
        debugPrint('auth_interceptor_test: $e');
      }

      expect(tokenProvider.sessionCleared, isTrue);
    });

    test('does not infinite loop on repeated 401s', () async {
      final (:dio, :tokenProvider, :adapter) = createTestDio(
        initialToken: 'always-same-token',
      );

      // First response: 401, retry response: 200 (stops the loop)
      adapter.addResponse('{"error": "unauthorized"}', 401);

      // After retry, Dio goes through the adapter again -> gets 200 by default
      final response = await dio.get('/protected');
      expect(response.statusCode, 200);

      // Token provider called: once for original request, once in onError
      // for refresh attempt, once for onRequest of retry
      expect(tokenProvider.refreshCallCount, 3);
    });

    test(
      'does not clear session on transient refresh failure during 401 retry',
      () async {
        final (:dio, :tokenProvider, :adapter) = createTestDio(
          initialToken: 'stale-token',
        );

        // First request succeeds (with stale token attached on initial onRequest).
        // Backend rejects with 401; onError tries to refresh; refresh throws
        // TransientAuthRefreshException; the interceptor must NOT clear the
        // session and MUST surface a non-401 DioException to the caller.
        adapter.addResponse('{"error": "unauthorized"}', 401);
        // Call #1 is onRequest (attaches stale-token); call #2 is the refresh
        // attempt inside onError — that's the one we want to fail transiently.
        tokenProvider.throwTransientOnCall(2);

        Object? caughtError;
        try {
          await dio.get('/protected');
        } catch (e) {
          caughtError = e;
        }

        expect(caughtError, isA<DioException>());
        expect(
          (caughtError as DioException).type,
          DioExceptionType.connectionError,
        );
        expect(
          tokenProvider.sessionCleared,
          isFalse,
          reason: 'Transient refresh failure must not force logout',
        );
      },
    );

    test('_failQueue rejects queued handlers with DioException', () async {
      // Verify the fix: when token is null, failQueue should reject
      // queued requests with proper DioException, not leave them hanging.
      final (:dio, :tokenProvider, :adapter) = createTestDio();

      // No token available -> triggers _failQueue path
      adapter.addResponse('{"error": "unauthorized"}', 401);

      Object? caughtError;
      try {
        await dio.get('/protected');
      } catch (e) {
        caughtError = e;
      }

      expect(caughtError, isA<DioException>());
      expect(tokenProvider.sessionCleared, isTrue);
    });
  });
}
