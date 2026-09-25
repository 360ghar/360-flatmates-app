import 'dart:async';

import 'package:dio/dio.dart';

import '../auth_token_provider.dart';

final class AuthInterceptor extends Interceptor {
  AuthInterceptor({required AuthTokenProvider tokenProvider, required Dio dio})
    : _tokenProvider = tokenProvider,
      _dio = dio;

  final AuthTokenProvider _tokenProvider;
  final Dio _dio;
  Completer<bool>? _refreshCompleter;
  final List<_QueuedRequest> _queuedRequests = [];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    String? token;
    try {
      token = await _tokenProvider.getAccessToken();
    } on TransientAuthRefreshException {
      // Transient refresh failure (network down, etc.). Proceed without auth;
      // backend will likely return 401 and onError can retry once. Do NOT
      // clear the session — the user may still be logged in.
      token = null;
    }
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.extra['_retried'] != true) {
      if (_refreshCompleter != null) {
        final completer = Completer<void>();
        _queuedRequests.add(
          _QueuedRequest(
            completer: completer,
            handler: handler,
            requestOptions: err.requestOptions,
          ),
        );
        await completer.future;
        return;
      }

      _refreshCompleter = Completer<bool>();
      String? newToken;
      try {
        newToken = await _tokenProvider.getAccessToken(
          rejectedToken: _bearer(err.requestOptions),
        );
      } on TransientAuthRefreshException catch (e) {
        // Refresh failed for transport reasons. Don't clear the session —
        // the user may still be logged in once the network is back. Fail
        // this request and the queue with the transient error.
        _finishRefresh(false);
        _failQueueTransient(e, err.stackTrace);
        handler.next(
          DioException(
            requestOptions: err.requestOptions,
            error: e,
            type: DioExceptionType.connectionError,
            stackTrace: err.stackTrace,
          ),
        );
        return;
      }

      if (newToken == null || newToken.isEmpty) {
        // No new token — session is genuinely gone. Clear and surface a 401.
        _finishRefresh(false);
        await _tokenProvider.clearSession();
        _failQueueSessionExpired(err.stackTrace);
        handler.next(
          DioException(
            requestOptions: err.requestOptions,
            error: 'Session expired. Please sign in again.',
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: err.requestOptions,
              statusCode: 401,
            ),
            stackTrace: err.stackTrace,
          ),
        );
        return;
      }

      // The session is valid again. Each queued request retries on its own,
      // so one failed retry (network, 5xx) never fails the others.
      _finishRefresh(true);
      unawaited(_processQueue(newToken));
      final opts = err.requestOptions;
      opts.extra['_retried'] = true;
      opts.headers['Authorization'] = 'Bearer $newToken';
      try {
        handler.resolve(await _dio.fetch(opts));
      } on DioException catch (e) {
        handler.next(e);
      } catch (e, st) {
        handler.next(
          DioException(requestOptions: opts, error: e, stackTrace: st),
        );
      }
    } else {
      handler.next(err);
    }
  }

  void _finishRefresh(bool refreshed) {
    _refreshCompleter?.complete(refreshed);
    _refreshCompleter = null;
  }

  static String? _bearer(RequestOptions options) {
    final header = options.headers['Authorization'];
    if (header is! String || !header.startsWith('Bearer ')) return null;
    return header.substring('Bearer '.length);
  }

  Future<void> _processQueue(String token) async {
    final queued = List<_QueuedRequest>.from(_queuedRequests);
    _queuedRequests.clear();
    for (final item in queued) {
      try {
        item.requestOptions.headers['Authorization'] = 'Bearer $token';
        item.requestOptions.extra['_retried'] = true;
        final response = await _dio.fetch(item.requestOptions);
        item.handler.resolve(response);
      } catch (e) {
        if (e is DioException) {
          item.handler.next(e);
        } else if (e is Error) {
          item.handler.next(
            DioException(
              requestOptions: item.requestOptions,
              error: e,
              stackTrace: e.stackTrace,
            ),
          );
        } else {
          item.handler.next(
            DioException(
              requestOptions: item.requestOptions,
              error: e,
              stackTrace: StackTrace.current,
            ),
          );
        }
      }
      item.completer.complete();
    }
  }

  void _failQueueSessionExpired(StackTrace? stackTrace) {
    final queued = List<_QueuedRequest>.from(_queuedRequests);
    _queuedRequests.clear();
    for (final item in queued) {
      item.handler.next(
        DioException(
          requestOptions: item.requestOptions,
          error: 'Session expired. Please sign in again.',
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: item.requestOptions,
            statusCode: 401,
          ),
          stackTrace: stackTrace,
        ),
      );
      item.completer.complete();
    }
  }

  void _failQueueTransient(
    TransientAuthRefreshException exception,
    StackTrace? stackTrace,
  ) {
    final queued = List<_QueuedRequest>.from(_queuedRequests);
    _queuedRequests.clear();
    for (final item in queued) {
      item.handler.next(
        DioException(
          requestOptions: item.requestOptions,
          error: exception,
          type: DioExceptionType.connectionError,
          stackTrace: stackTrace,
        ),
      );
      item.completer.complete();
    }
  }
}

class _QueuedRequest {
  const _QueuedRequest({
    required this.completer,
    required this.handler,
    required this.requestOptions,
  });

  final Completer<void> completer;
  final ErrorInterceptorHandler handler;
  final RequestOptions requestOptions;
}
