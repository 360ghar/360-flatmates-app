import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../errors/error_presenter.dart';
import 'auth_token_provider.dart';
import 'interceptors/auth_interceptor.dart';

final class ApiClient {
  ApiClient({required String baseUrl, required AuthTokenProvider tokenProvider})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          // Interactive GETs should fail fast enough for retry UX; large
          // uploads override send/receive via Options on the request.
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 60),
          // Explicit JSON content-type so PUT/POST body maps are never sent
          // as empty form data (which would soft-succeed profile updates).
          // Per-request Options (e.g. multipart uploads) override this.
          headers: const {'Accept': 'application/json'},
          contentType: Headers.jsonContentType,
        ),
      ) {
    _dio.interceptors.add(
      AuthInterceptor(tokenProvider: tokenProvider, dio: _dio),
    );
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          // Log bodies + status so profile-completion / gate failures are
          // diagnosable (statusCode is only printed when responseHeader is on).
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint('🌐 $obj'),
        ),
      );
      // TODO: Add Alice HTTP inspector when compatible version is available
      // Currently alice dev_dependency conflicts with share_plus ^10.1.4
    }
  }

  /// Per-request timeouts for cold-start critical paths (bootstrap, auth-state,
  /// version check). Keeps splash recovery under ~15s when the API/DB is
  /// wedged instead of waiting for the default 30s receive timeout twice.
  static Options criticalPathOptions({
    Duration timeout = const Duration(seconds: 15),
  }) => Options(
    connectTimeout: timeout,
    sendTimeout: timeout,
    receiveTimeout: timeout,
  );

  final Dio _dio;

  Dio get dio => _dio;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e, st) {
      throw ErrorPresenter.fromDio(e, st);
    }
  }

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e, st) {
      throw ErrorPresenter.fromDio(e, st);
    }
  }

  Future<Response<dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e, st) {
      throw ErrorPresenter.fromDio(e, st);
    }
  }

  Future<Response<dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e, st) {
      throw ErrorPresenter.fromDio(e, st);
    }
  }
}
