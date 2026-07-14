import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import 'package:flatmates_app/core/errors/app_failure.dart';
import 'package:flatmates_app/core/errors/error_presenter.dart';

/// A minimal [UserMessageL10n] for testing — each field is a distinct string
/// so we can assert which message was returned.
const _testL10n = UserMessageL10n(
  errorNetwork: 'Network error',
  errorAuthExpired: 'Auth expired',
  errorAuth: 'Auth error',
  errorServer: 'Server error',
  errorPermission: 'Permission error',
  errorNotFound: 'Not found',
  errorValidation: 'Validation error',
  errorRateLimit: 'Rate limit',
  errorConflict: 'Conflict',
  errorUpload: 'Upload error',
  errorOtpInvalid: 'OTP invalid',
  errorAuthSessionMissing: 'Session missing',
  errorUnknown: 'Unknown error',
);

void main() {
  group('AppFailure hierarchy', () {
    test('NetworkFailure has correct label and userMessage', () {
      const failure = NetworkFailure();
      expect(failure.label, 'network');
      expect(failure.userMessage(_testL10n), 'Network error');
    });

    test('AuthExpiredFailure has correct label and userMessage', () {
      const failure = AuthExpiredFailure();
      expect(failure.label, 'auth_expired');
      expect(failure.userMessage(_testL10n), 'Auth expired');
    });

    test('AuthExpiredFailure uses serverMessage when provided', () {
      const failure = AuthExpiredFailure(serverMessage: 'Token revoked');
      expect(failure.userMessage(_testL10n), 'Token revoked');
    });

    test('ServerFailure has correct label with statusCode', () {
      const failure = ServerFailure(statusCode: 500);
      expect(failure.label, 'server(500)');
      expect(failure.userMessage(_testL10n), 'Server error');
    });

    test('ServerFailure uses serverMessage when provided', () {
      const failure = ServerFailure(
        statusCode: 503,
        serverMessage: 'Maintenance',
      );
      expect(failure.userMessage(_testL10n), 'Maintenance');
    });

    test('PermissionFailure has correct label and userMessage', () {
      const failure = PermissionFailure();
      expect(failure.label, 'permission');
      expect(failure.userMessage(_testL10n), 'Permission error');
    });

    test('NotFoundFailure has correct label and userMessage', () {
      const failure = NotFoundFailure();
      expect(failure.label, 'not_found');
      expect(failure.userMessage(_testL10n), 'Not found');
    });

    test('ValidationFailure has correct label', () {
      const failure = ValidationFailure();
      expect(failure.label, 'validation');
      expect(failure.userMessage(_testL10n), 'Validation error');
    });

    test('ValidationFailure joins field messages when present', () {
      const failure = ValidationFailure(
        fieldMessages: {'email': 'Invalid email', 'name': 'Name too short'},
      );
      final message = failure.userMessage(_testL10n);
      expect(message, contains('Invalid email'));
      expect(message, contains('Name too short'));
    });

    test('RateLimitFailure has correct label and userMessage', () {
      const failure = RateLimitFailure();
      expect(failure.label, 'rate_limit');
      expect(failure.userMessage(_testL10n), 'Rate limit');
    });

    test('ConflictFailure has correct label and userMessage', () {
      const failure = ConflictFailure();
      expect(failure.label, 'conflict');
      expect(failure.userMessage(_testL10n), 'Conflict');
    });

    test('UploadFailure has correct label', () {
      const failure = UploadFailure();
      expect(failure.label, 'upload');
      expect(failure.userMessage(_testL10n), 'Upload error');
    });

    test('UploadFailure includes reason when provided', () {
      const failure = UploadFailure(reason: 'File too large');
      expect(failure.userMessage(_testL10n), 'Upload error: File too large');
    });

    test('UnknownFailure has correct label and userMessage', () {
      const failure = UnknownFailure();
      expect(failure.label, 'unknown');
      expect(failure.userMessage(_testL10n), 'Unknown error');
    });

    test('UnknownFailure uses serverMessage when provided', () {
      const failure = UnknownFailure(serverMessage: 'Something broke');
      expect(failure.userMessage(_testL10n), 'Something broke');
    });
  });

  group('ErrorPresenter.fromDio', () {
    test('connectionTimeout maps to NetworkFailure', () {
      final exception = DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );
      final failure = ErrorPresenter.fromDio(exception);
      expect(failure, isA<NetworkFailure>());
    });

    test('sendTimeout maps to NetworkFailure', () {
      final exception = DioException(
        type: DioExceptionType.sendTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );
      final failure = ErrorPresenter.fromDio(exception);
      expect(failure, isA<NetworkFailure>());
    });

    test('receiveTimeout maps to NetworkFailure', () {
      final exception = DioException(
        type: DioExceptionType.receiveTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );
      final failure = ErrorPresenter.fromDio(exception);
      expect(failure, isA<NetworkFailure>());
    });

    test('connectionError maps to NetworkFailure', () {
      final exception = DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: '/test'),
      );
      final failure = ErrorPresenter.fromDio(exception);
      expect(failure, isA<NetworkFailure>());
    });

    test('401 badResponse maps to AuthExpiredFailure', () {
      final exception = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
        ),
      );
      final failure = ErrorPresenter.fromDio(exception);
      expect(failure, isA<AuthExpiredFailure>());
    });

    test('403 badResponse maps to PermissionFailure', () {
      final exception = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 403,
        ),
      );
      final failure = ErrorPresenter.fromDio(exception);
      expect(failure, isA<PermissionFailure>());
    });

    test('404 badResponse maps to NotFoundFailure', () {
      final exception = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 404,
        ),
      );
      final failure = ErrorPresenter.fromDio(exception);
      expect(failure, isA<NotFoundFailure>());
    });

    test('409 badResponse maps to ConflictFailure', () {
      final exception = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 409,
        ),
      );
      final failure = ErrorPresenter.fromDio(exception);
      expect(failure, isA<ConflictFailure>());
    });

    test('422 badResponse maps to ValidationFailure', () {
      final exception = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 422,
          data: {
            'detail': {'email': 'Invalid email'},
          },
        ),
      );
      final failure = ErrorPresenter.fromDio(exception);
      expect(failure, isA<ValidationFailure>());
      final validation = failure as ValidationFailure;
      expect(validation.fieldMessages['email'], 'Invalid email');
    });

    test('429 badResponse maps to RateLimitFailure', () {
      final exception = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 429,
        ),
      );
      final failure = ErrorPresenter.fromDio(exception);
      expect(failure, isA<RateLimitFailure>());
    });

    test('500 badResponse maps to ServerFailure', () {
      final exception = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        ),
      );
      final failure = ErrorPresenter.fromDio(exception);
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 500);
    });

    test('cancel maps to UnknownFailure', () {
      final exception = DioException(
        type: DioExceptionType.cancel,
        requestOptions: RequestOptions(path: '/test'),
      );
      final failure = ErrorPresenter.fromDio(exception);
      expect(failure, isA<UnknownFailure>());
    });

    test('400 badResponse maps to ValidationFailure', () {
      final exception = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 400,
          data: {'detail': 'Bad request'},
        ),
      );
      final failure = ErrorPresenter.fromDio(exception);
      expect(failure, isA<ValidationFailure>());
    });

    test('extracts server message from detail string', () {
      final exception = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
          data: {'detail': 'Token expired'},
        ),
      );
      final failure = ErrorPresenter.fromDio(exception);
      expect(failure, isA<AuthExpiredFailure>());
      expect((failure as AuthExpiredFailure).serverMessage, 'Token expired');
    });
  });
}
