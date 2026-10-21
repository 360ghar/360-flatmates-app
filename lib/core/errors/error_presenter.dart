import 'dart:io';

import 'package:dio/dio.dart';

import 'api_error_envelope.dart';
import 'app_failure.dart';

/// Converts a [DioException] (from the network layer) into a typed
/// [AppFailure] that the rest of the app can use.
///
/// Usage in repositories:
/// ```dart
/// try {
///   final response = await apiClient.get('/endpoint');
///   return parseResponse(response);
/// } on DioException catch (e, st) {
///   throw ErrorPresenter.fromDio(e, st);
/// }
/// ```
///
/// For non-Dio errors:
/// ```dart
/// } catch (e, st) {
///   throw UnknownFailure(underlyingError: e, stackTrace: st);
/// }
/// ```
final class ErrorPresenter {
  const ErrorPresenter._();

  /// Maps a [DioException] to the appropriate [AppFailure] subclass.
  static AppFailure fromDio(DioException e, [StackTrace? st]) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => NetworkFailure(
        kind: NetworkFailureKind.timeout,
        underlyingError: e,
        stackTrace: st,
      ),
      DioExceptionType.connectionError => _fromConnectionError(e, st),
      DioExceptionType.badResponse => _fromStatusCode(
        e.response?.statusCode,
        e,
        st,
      ),
      DioExceptionType.cancel => UnknownFailure(
        underlyingError: e,
        stackTrace: st,
      ),
      // Certificate/TLS problems are not "no internet" — device is online.
      DioExceptionType.badCertificate => NetworkFailure(
        kind: NetworkFailureKind.unreachable,
        underlyingError: e,
        stackTrace: st,
      ),
      DioExceptionType.unknown => _fromUnknown(e, st),
    };
  }

  /// Maps an HTTP error status to a typed failure. The text and the code come
  /// from the error envelope only (`{"error": {"code", "message", "details"}}`).
  static AppFailure _fromStatusCode(
    int? statusCode,
    DioException e,
    StackTrace? st,
  ) {
    final envelope = ApiErrorEnvelope.tryParse(e.response?.data);
    final serverMessage = _nonEmpty(envelope?.message);
    final code = envelope?.code;
    return switch (statusCode) {
      400 => _fromBadRequest(envelope, e, st),
      401 => AuthExpiredFailure(
        serverMessage: serverMessage,
        code: code,
        underlyingError: e,
        stackTrace: st,
      ),
      403 => PermissionFailure(
        serverMessage: serverMessage,
        code: code,
        underlyingError: e,
        stackTrace: st,
      ),
      404 => NotFoundFailure(
        serverMessage: serverMessage,
        code: code,
        underlyingError: e,
        stackTrace: st,
      ),
      409 => ConflictFailure(
        serverMessage: serverMessage,
        code: code,
        underlyingError: e,
        stackTrace: st,
      ),
      422 => _fromValidationResponse(envelope, e, st),
      429 => RateLimitFailure(
        serverMessage: serverMessage,
        retryAfter: _retryAfter(e),
        code: code,
        underlyingError: e,
        stackTrace: st,
      ),
      _ when (statusCode ?? 500) >= 500 => ServerFailure(
        statusCode: statusCode,
        serverMessage: serverMessage,
        retryAfter: _retryAfter(e),
        code: code,
        underlyingError: e,
        stackTrace: st,
      ),
      _ => UnknownFailure(
        serverMessage: serverMessage,
        code: code,
        underlyingError: e,
        stackTrace: st,
      ),
    };
  }

  static String? _nonEmpty(String? value) =>
      value == null || value.trim().isEmpty ? null : value;

  /// The `Retry-After` header in seconds, when the server sent one (429 and
  /// 503). An HTTP-date value is ignored: the backend sends seconds.
  static Duration? _retryAfter(DioException e) {
    final raw = e.response?.headers.value('retry-after');
    final seconds = raw == null ? null : int.tryParse(raw.trim());
    if (seconds == null || seconds < 0) return null;
    return Duration(seconds: seconds);
  }

  /// A 400 carries one message in the envelope; there are no field errors.
  static AppFailure _fromBadRequest(
    ApiErrorEnvelope? envelope,
    DioException e,
    StackTrace? st,
  ) {
    final message = _nonEmpty(envelope?.message);
    return ValidationFailure(
      fieldMessages: message == null ? const {} : {'detail': message},
      code: envelope?.code,
      underlyingError: e,
      stackTrace: st,
    );
  }

  /// A 422 lists its field errors in `error.details.fields`
  /// (`{field, msg, type}`). With no field named, the envelope message is used
  /// unless it is the generic `VALIDATION_ERROR` text.
  static AppFailure _fromValidationResponse(
    ApiErrorEnvelope? envelope,
    DioException e,
    StackTrace? st,
  ) {
    final fieldMessages = <String, String>{};
    for (final error in envelope?.fields ?? const <ApiFieldError>[]) {
      fieldMessages.putIfAbsent(error.formField, () => error.msg);
    }
    final message = _nonEmpty(envelope?.message);
    if (fieldMessages.isEmpty &&
        message != null &&
        envelope?.code != 'VALIDATION_ERROR') {
      fieldMessages['detail'] = message;
    }
    return ValidationFailure(
      fieldMessages: fieldMessages,
      code: envelope?.code,
      underlyingError: e,
      stackTrace: st,
    );
  }

  static AppFailure _fromConnectionError(DioException e, StackTrace? st) {
    final message = _combinedMessage(e);
    final kind = _classifyTransportMessage(message);
    return NetworkFailure(kind: kind, underlyingError: e, stackTrace: st);
  }

  static AppFailure _fromUnknown(DioException e, StackTrace? st) {
    final error = e.error;
    if (error is SocketException ||
        error is HandshakeException ||
        error is HttpException) {
      final message = _combinedMessage(e);
      return NetworkFailure(
        kind: _classifyTransportMessage(message),
        underlyingError: e,
        stackTrace: st,
      );
    }

    final message = _combinedMessage(e);
    if (_looksLikeNetworkFailure(message)) {
      return NetworkFailure(
        kind: _classifyTransportMessage(message),
        underlyingError: e,
        stackTrace: st,
      );
    }
    return UnknownFailure(underlyingError: e, stackTrace: st);
  }

  static String _combinedMessage(DioException e) =>
      '${e.message ?? ''} ${e.error ?? ''}'.toLowerCase();

  /// Prefer precise copy over always saying "no internet".
  ///
  /// Timeouts and "host unreachable / connection refused" commonly happen with
  /// Wi‑Fi still up (slow API, bad base URL, server restart). Only mark true
  /// offline when the OS reports the link as unreachable.
  static NetworkFailureKind _classifyTransportMessage(String message) {
    if (_looksLikeTimeout(message)) {
      return NetworkFailureKind.timeout;
    }
    if (_looksLikeOffline(message)) {
      return NetworkFailureKind.offline;
    }
    // Default for connectionError / DNS / refused / TLS: not "no internet".
    return NetworkFailureKind.unreachable;
  }

  static bool _looksLikeTimeout(String message) {
    return message.contains('timed out') ||
        message.contains('timeout') ||
        message.contains('timeoutexception');
  }

  static bool _looksLikeOffline(String message) {
    // Reserve "offline" for link-down signals only. DNS / hostname resolution
    // and connection-abort can happen while Wi‑Fi is up (bad host, flaky DNS)
    // — those fall through to `unreachable` in `_classifyTransportMessage`.
    return message.contains('network is unreachable') ||
        message.contains('no route to host') ||
        message.contains('offline');
  }

  static bool _looksLikeNetworkFailure(String message) {
    const markers = [
      'socketexception',
      'handshakeexception',
      'httpexception',
      'failed host lookup',
      'connection refused',
      'connection reset',
      'connection closed',
      'connection aborted',
      'network is unreachable',
      'no route to host',
      'cleartext',
      'app transport security',
      'operation timed out',
      'timed out',
      'timeout',
      'certificate',
      'tls',
      'ssl',
    ];

    return markers.any(message.contains);
  }
}
