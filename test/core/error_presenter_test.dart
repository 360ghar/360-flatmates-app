import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/errors/app_failure.dart';
import 'package:flatmates_app/core/errors/error_presenter.dart';

DioException _makeDioError(
  DioExceptionType type, {
  int? statusCode,
  Object? error,
}) {
  return DioException(
    requestOptions: RequestOptions(),
    type: type,
    response: statusCode != null
        ? Response(requestOptions: RequestOptions(), statusCode: statusCode)
        : null,
    error: error,
  );
}

void main() {
  group('ErrorPresenter', () {
    test('connectionTimeout -> NetworkFailure', () {
      final result = ErrorPresenter.fromDio(
        _makeDioError(DioExceptionType.connectionTimeout),
      );
      expect(result, isA<NetworkFailure>());
    });
    test('connectionError -> NetworkFailure', () {
      final result = ErrorPresenter.fromDio(
        _makeDioError(DioExceptionType.connectionError),
      );
      expect(result, isA<NetworkFailure>());
    });
    test('401 -> AuthExpiredFailure', () {
      final result = ErrorPresenter.fromDio(
        _makeDioError(DioExceptionType.badResponse, statusCode: 401),
      );
      expect(result, isA<AuthExpiredFailure>());
    });
    test('403 -> PermissionFailure', () {
      final result = ErrorPresenter.fromDio(
        _makeDioError(DioExceptionType.badResponse, statusCode: 403),
      );
      expect(result, isA<PermissionFailure>());
    });
    test('404 -> NotFoundFailure', () {
      final result = ErrorPresenter.fromDio(
        _makeDioError(DioExceptionType.badResponse, statusCode: 404),
      );
      expect(result, isA<NotFoundFailure>());
    });
    test('409 -> ConflictFailure', () {
      final result = ErrorPresenter.fromDio(
        _makeDioError(DioExceptionType.badResponse, statusCode: 409),
      );
      expect(result, isA<ConflictFailure>());
    });
    test('422 with detail map -> ValidationFailure with field messages', () {
      final e = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 422,
          data: {
            'detail': {'email': 'Invalid email'},
          },
        ),
      );
      final result = ErrorPresenter.fromDio(e);
      expect(result, isA<ValidationFailure>());
      expect(
        (result as ValidationFailure).fieldMessages['email'],
        'Invalid email',
      );
    });
    test('429 -> RateLimitFailure', () {
      final result = ErrorPresenter.fromDio(
        _makeDioError(DioExceptionType.badResponse, statusCode: 429),
      );
      expect(result, isA<RateLimitFailure>());
    });
    test('500 -> ServerFailure', () {
      final result = ErrorPresenter.fromDio(
        _makeDioError(DioExceptionType.badResponse, statusCode: 500),
      );
      expect(result, isA<ServerFailure>());
      expect((result as ServerFailure).statusCode, 500);
    });
    test('unknown with SocketException -> NetworkFailure', () {
      final result = ErrorPresenter.fromDio(
        _makeDioError(
          DioExceptionType.unknown,
          error: const SocketException('No connection'),
        ),
      );
      expect(result, isA<NetworkFailure>());
    });
    test('unknown with HandshakeException -> NetworkFailure', () {
      final result = ErrorPresenter.fromDio(
        _makeDioError(
          DioExceptionType.unknown,
          error: const HandshakeException('TLS failed'),
        ),
      );
      expect(result, isA<NetworkFailure>());
    });
    test('unknown cleartext policy message -> NetworkFailure', () {
      final result = ErrorPresenter.fromDio(
        DioException(
          requestOptions: RequestOptions(),
          message: 'Cleartext HTTP traffic to 192.168.1.14 not permitted',
        ),
      );
      expect(result, isA<NetworkFailure>());
    });
    test('unknown without SocketException -> UnknownFailure', () {
      final result = ErrorPresenter.fromDio(
        _makeDioError(DioExceptionType.unknown, error: Exception('Something')),
      );
      expect(result, isA<UnknownFailure>());
    });
  });
}
