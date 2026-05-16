import 'package:dio/dio.dart';

import '../errors/error_presenter.dart';
import 'auth_token_provider.dart';
import 'interceptors/auth_interceptor.dart';

final class ApiClient {
  ApiClient({
    required String baseUrl,
    required AuthTokenProvider tokenProvider,
    required bool enableLogging,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 30),
           receiveTimeout: const Duration(seconds: 30),
           sendTimeout: const Duration(seconds: 30),
           headers: const {'Accept': 'application/json'},
         ),
       ) {
    _dio.interceptors.add(
      AuthInterceptor(tokenProvider: tokenProvider, dio: _dio),
    );
    if (enableLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: false,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }
  }

  final Dio _dio;

  Dio get dio => _dio;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e, st) {
      throw ErrorPresenter.fromDio(e, st);
    }
  }

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e, st) {
      throw ErrorPresenter.fromDio(e, st);
    }
  }

  Future<Response<dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e, st) {
      throw ErrorPresenter.fromDio(e, st);
    }
  }

  Future<Response<dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e, st) {
      throw ErrorPresenter.fromDio(e, st);
    }
  }
}
