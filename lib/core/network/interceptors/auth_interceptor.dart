import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
      final rejectedToken = _bearer(err.requestOptions);
      String? newToken;
      try {
        newToken = await _tokenProvider.getAccessToken(
          rejectedToken: rejectedToken,
        );
      } on TransientAuthRefreshException catch (e) {
        // Refresh failed for transport reasons. Don't clear the session —
        // the user may still be logged in once the network is back. Fail
        // this request and the queue with the transient error.
        _finishRefresh(false);
        _failQueueWith(
          e,
          type: DioExceptionType.connectionError,
          stackTrace: err.stackTrace,
        );
        handler.next(
          DioException(
            requestOptions: err.requestOptions,
            error: e,
            type: DioExceptionType.connectionError,
            stackTrace: err.stackTrace,
          ),
        );
        return;
      } catch (e, st) {
        // Any other provider failure (Supabase SDK error, storage error, a
        // programming error) must still release the refresh gate and drain
        // the queue. Otherwise `_refreshCompleter` stays set and every later
        // 401 queues behind a completer nobody completes.
        debugPrint('AuthInterceptor.onError: token refresh failed: $e');
        _finishRefresh(false);
        _failQueueWith(e, type: DioExceptionType.unknown, stackTrace: st);
        handler.next(
          DioException(
            requestOptions: err.requestOptions,
            error: e,
            stackTrace: st,
          ),
        );
        return;
      }

      if (newToken == null || newToken.isEmpty) {
        // No new token — session is genuinely gone. Drain the queue before
        // touching the session store: clearing it deletes from the keychain
        // and can throw (for example iOS error -25308), and a throw here would
        // leave every queued request waiting on a completer nobody completes.
        _finishRefresh(false);
        _failQueueWith(
          'Session expired. Please sign in again.',
          type: DioExceptionType.badResponse,
          statusCode: 401,
          stackTrace: err.stackTrace,
        );
        try {
          await _tokenProvider.clearSession();
        } catch (e) {
          debugPrint('AuthInterceptor.onError: clearSession failed: $e');
        }
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

      if (rejectedToken != null && newToken == rejectedToken) {
        // The provider handed back the very token the server just rejected,
        // so retrying with it can only 401 again. Fail this request and the
        // queue without the extra round trip; the session is left intact
        // (the provider clears it when the session is genuinely gone).
        debugPrint(
          'AuthInterceptor.onError: refresh returned the rejected token',
        );
        _finishRefresh(false);
        _failQueueWith(
          err.error ?? 'Unauthorized',
          type: DioExceptionType.badResponse,
          statusCode: 401,
          stackTrace: err.stackTrace,
        );
        handler.next(err);
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

  void _failQueueWith(
    Object error, {
    required DioExceptionType type,
    int? statusCode,
    StackTrace? stackTrace,
  }) {
    final queued = List<_QueuedRequest>.from(_queuedRequests);
    _queuedRequests.clear();
    for (final item in queued) {
      item.handler.next(
        DioException(
          requestOptions: item.requestOptions,
          error: error,
          type: type,
          response: statusCode == null
              ? null
              : Response(
                  requestOptions: item.requestOptions,
                  statusCode: statusCode,
                ),
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
