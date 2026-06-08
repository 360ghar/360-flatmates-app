import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../errors/error_presenter.dart';
import 'auth_token_provider.dart';
import 'interceptors/auth_interceptor.dart';

final class ApiClient {
  ApiClient({
    required String baseUrl,
    required AuthTokenProvider tokenProvider,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
            headers: const {'Accept': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      AuthInterceptor(tokenProvider: tokenProvider, dio: _dio),
    );
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          logPrint: (obj) => debugPrint('🌐 $obj'),
        ),
      );
      // TODO: Add Alice HTTP inspector when compatible version is available
      // Currently alice dev_dependency conflicts with share_plus ^10.1.4
    }
  }

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
