import 'package:dio/dio.dart';
import 'package:flatmates_app/core/errors/api_error_envelope.dart';
import 'package:flatmates_app/core/errors/app_failure.dart';
import 'package:flatmates_app/core/errors/error_presenter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'api_fixtures.dart';

UserMessageL10n _l10nWith([Map<String, String> codes = const {}]) =>
    UserMessageL10n(
      errorNetwork: 'Network error',
      errorTimeout: 'Timeout error',
      errorCannotReachServer: 'Unreachable error',
      errorAuthExpired: 'Auth expired',
      errorAuth: 'Auth error',
      errorServer: 'Server error',
      errorServerWait: (seconds) => 'Server wait $seconds s',
      errorPermission: 'Permission error',
      errorNotFound: 'Not found',
      errorValidation: 'Validation error',
      errorRateLimit: 'Rate limit',
      errorRateLimitWait: (seconds) => 'Rate limit wait $seconds s',
      errorConflict: 'Conflict',
      errorUpload: 'Upload error',
      errorOtpInvalid: 'OTP invalid',
      errorAuthSessionMissing: 'Session missing',
      errorUnknown: 'Unknown error',
      codeMessages: codes,
    );

final _l10n = _l10nWith();

DioException _error(
  int status,
  Object? body, {
  Map<String, List<String>> headers = const {},
}) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: status,
      data: body,
      headers: Headers.fromMap(headers),
    ),
  );
}

/// Every non-2xx body of the backend is `{error: {code, message, details}}`.
/// The fixtures are built by the backend's own `ErrorEnvelope` models.
void main() {
  final errors = apiFixtureGroup('errors');
  Map<String, dynamic> envelope(String name) =>
      Map<String, dynamic>.from(errors[name] as Map);
  String messageOf(String name) =>
      ((errors[name] as Map)['error'] as Map)['message'] as String;
  String codeOf(String name) =>
      ((errors[name] as Map)['error'] as Map)['code'] as String;

  group('error envelope parsing', () {
    test('reads code, message and details of every fixture', () {
      for (final name in errors.keys) {
        final parsed = ApiErrorEnvelope.tryParse(errors[name]);
        expect(parsed, isNotNull, reason: name);
        expect(parsed!.code, codeOf(name), reason: name);
        expect(parsed.message, messageOf(name), reason: name);
        final details = ((errors[name] as Map)['error'] as Map)['details'];
        expect(
          parsed.details,
          details is Map ? details : isEmpty,
          reason: '$name details',
        );
      }
    });

    test('a 422 lists field errors in details.fields', () {
      final parsed = ApiErrorEnvelope.tryParse(errors['validation'])!;

      expect(parsed.fields, hasLength(3));
      expect(parsed.fields.first.field, 'body.reason');
      expect(parsed.fields.first.formField, 'reason');
      expect(parsed.fields.first.type, 'string_too_short');
      // The source prefix of a query field is kept.
      expect(parsed.fields.last.field, 'query.limit');
    });

    test('a 422 without a field has an empty list', () {
      final parsed = ApiErrorEnvelope.tryParse(errors['validation_no_fields'])!;

      expect(parsed.fields, isEmpty);
      expect(parsed.code, 'INVALID_CURSOR');
    });

    test('a body that is not an envelope is not parsed', () {
      expect(ApiErrorEnvelope.tryParse(null), isNull);
      expect(ApiErrorEnvelope.tryParse('<html>Bad gateway</html>'), isNull);
      expect(ApiErrorEnvelope.tryParse({'detail': 'old shape'}), isNull);
      expect(
        ApiErrorEnvelope.tryParse({
          'error': {'code': 'X'},
        }),
        isNull,
      );
    });
  });

  group('every status maps to a typed failure with the envelope text', () {
    test('400 keeps the message', () {
      final failure = ErrorPresenter.fromDio(
        _error(400, envelope('bad_request')),
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure.code, 'BAD_REQUEST');
      expect(
        (failure as ValidationFailure).fieldMessages['detail'],
        'Conversation is not active',
      );
    });

    test('401 keeps code and message', () {
      final failure = ErrorPresenter.fromDio(
        _error(401, envelope('unauthorized')),
      );

      expect(failure, isA<AuthExpiredFailure>());
      expect(failure.code, 'TOKEN_INVALID');
      expect(failure.userMessage(_l10n), messageOf('unauthorized'));
    });

    test('403 keeps code and message', () {
      final failure = ErrorPresenter.fromDio(
        _error(403, envelope('forbidden')),
      );

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, 'FORBIDDEN');
      expect(failure.userMessage(_l10n), messageOf('forbidden'));
    });

    test('404 keeps the domain code', () {
      final failure = ErrorPresenter.fromDio(
        _error(404, envelope('not_found')),
      );

      expect(failure, isA<NotFoundFailure>());
      expect(failure.code, 'MATCH_NOT_FOUND');
      expect(failure.userMessage(_l10n), messageOf('not_found'));
    });

    test('409 keeps code and message for the status conflict', () {
      final failure = ErrorPresenter.fromDio(
        _error(409, envelope('listing_status_conflict')),
      );

      expect(failure, isA<ConflictFailure>());
      expect(failure.code, 'LISTING_STATUS_CONFLICT');
      expect(failure.userMessage(_l10n), messageOf('listing_status_conflict'));
    });

    test('409 PROFILE_STATUS_LOCKED is a conflict with its code', () {
      final failure = ErrorPresenter.fromDio(
        _error(409, envelope('profile_status_locked')),
      );

      expect(failure, isA<ConflictFailure>());
      expect(failure.code, 'PROFILE_STATUS_LOCKED');
    });

    test('422 reads details.fields into field messages', () {
      final failure = ErrorPresenter.fromDio(
        _error(422, envelope('validation')),
      );

      expect(failure, isA<ValidationFailure>());
      final fields = (failure as ValidationFailure).fieldMessages;
      expect(failure.code, 'VALIDATION_ERROR');
      expect(fields['reason'], 'String should have at least 1 character');
      expect(fields['full_name'], 'Field required');
      expect(
        fields['query.limit'],
        'Input should be less than or equal to 100',
      );
    });

    test('422 without a field keeps the message of the envelope', () {
      final failure = ErrorPresenter.fromDio(
        _error(422, envelope('validation_no_fields')),
      );

      expect(failure.code, 'INVALID_CURSOR');
      expect(
        (failure as ValidationFailure).fieldMessages['detail'],
        'Cursor does not match',
      );
    });

    test('the old FastAPI detail list is not parsed any more', () {
      final failure = ErrorPresenter.fromDio(
        _error(422, {
          'detail': [
            {
              'loc': ['body', 'x'],
              'msg': 'Field required',
              'type': 'missing',
            },
          ],
        }),
      );

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).fieldMessages, isEmpty);
    });

    test('429 keeps the code and reads Retry-After', () {
      final failure = ErrorPresenter.fromDio(
        _error(
          429,
          envelope('rate_limited'),
          headers: {
            'retry-after': ['60'],
          },
        ),
      );

      expect(failure, isA<RateLimitFailure>());
      expect(failure.code, 'RATE_LIMIT_EXCEEDED');
      expect(
        (failure as RateLimitFailure).retryAfter,
        const Duration(seconds: 60),
      );
      // The wait is honoured in the message: the seconds replace the vague
      // "wait a moment" copy.
      expect(failure.userMessage(_l10n), 'Rate limit wait 60 s');
    });

    test('a 429 with Retry-After 0 keeps the plain copy', () {
      final failure = ErrorPresenter.fromDio(
        _error(
          429,
          envelope('rate_limited'),
          headers: {
            'retry-after': ['0'],
          },
        ),
      );

      expect((failure as RateLimitFailure).retryAfter, Duration.zero);
      expect(failure.userMessage(_l10n), messageOf('rate_limited'));
    });

    test('503 reads Retry-After', () {
      final failure = ErrorPresenter.fromDio(
        _error(
          503,
          envelope('unavailable'),
          headers: {
            'retry-after': ['5'],
          },
        ),
      );

      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 503);
      expect(failure.retryAfter, const Duration(seconds: 5));
      expect(failure.code, 'SERVICE_UNAVAILABLE');
      expect(failure.userMessage(_l10n), 'Server wait 5 s');
    });

    test('a 5xx never shows the backend text', () {
      final failure = ErrorPresenter.fromDio(_error(500, envelope('server')));

      expect(failure, isA<ServerFailure>());
      expect(failure.code, 'INTERNAL_ERROR');
      expect(failure.userMessage(_l10n), 'Server error');
    });

    test('an HTML gateway page maps by status with no message', () {
      final failure = ErrorPresenter.fromDio(
        _error(502, '<html>Bad gateway</html>'),
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.code, isNull);
      expect(failure.userMessage(_l10n), 'Server error');
    });
  });

  group('codes the app has copy for', () {
    final withCopy = _l10nWith({
      'PROFILE_NOT_FOUND': 'Profile gone',
      'PROFILE_STATUS_LOCKED': 'Status locked',
      'LISTING_STATUS_CONFLICT': 'Listing busy',
      'USER_INACTIVE': 'Account inactive',
    });

    test('the app copy of the code wins over the backend text', () {
      for (final entry in {
        'profile_not_found': (404, 'Profile gone'),
        'profile_status_locked': (409, 'Status locked'),
        'listing_status_conflict': (409, 'Listing busy'),
        'inactive': (403, 'Account inactive'),
      }.entries) {
        final failure = ErrorPresenter.fromDio(
          _error(entry.value.$1, envelope(entry.key)),
        );

        expect(failure.code, codeOf(entry.key), reason: entry.key);
        // The backend text is English only: the code picks the copy.
        expect(
          failure.userMessage(withCopy),
          entry.value.$2,
          reason: entry.key,
        );
        expect(
          failure.userMessage(_l10n),
          messageOf(entry.key),
          reason: '${entry.key} falls back to the backend text with no copy',
        );
      }
    });

    test('a code with no copy keeps the backend text', () {
      final failure = ErrorPresenter.fromDio(_error(409, envelope('conflict')));

      expect(failure.userMessage(withCopy), messageOf('conflict'));
    });
  });
}
