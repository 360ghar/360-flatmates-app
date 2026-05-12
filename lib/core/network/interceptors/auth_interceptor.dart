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
    final token = await _tokenProvider.getAccessToken();
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
      try {
        final newToken = await _tokenProvider.getAccessToken();
        if (newToken != null && newToken.isNotEmpty) {
          final opts = err.requestOptions;
          opts.extra['_retried'] = true;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final response = await _dio.fetch(opts);
          _refreshCompleter!.complete(true);
          _refreshCompleter = null;
          handler.resolve(response);
          _processQueue(newToken);
          return;
        }
        _refreshCompleter!.complete(false);
        _refreshCompleter = null;
        _failQueue(err.stackTrace);
      } catch (e) {
        _refreshCompleter!.complete(false);
        _refreshCompleter = null;
        _failQueue(e is DioException ? e.stackTrace : null);
      }
      await _tokenProvider.clearSession();
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
    } else {
      handler.next(err);
    }
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

  void _failQueue(StackTrace? stackTrace) {
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
