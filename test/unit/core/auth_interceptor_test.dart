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
  Future<String?> getAccessToken() async => _token;

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
  });
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

  @override
  void next(DioException err) {
    nextCalled = true;
    capturedError = err;
  }
}
