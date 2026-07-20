import 'dart:io';

import 'package:dio/dio.dart';

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
      DioExceptionType.receiveTimeout => NetworkFailure(
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

  static AppFailure _fromStatusCode(
    int? statusCode,
    DioException e,
    StackTrace? st,
  ) {
    final serverMessage = _extractServerMessage(e);
    return switch (statusCode) {
      400 => _fromBadRequest(e, st),
      401 => AuthExpiredFailure(
        serverMessage: serverMessage,
        underlyingError: e,
        stackTrace: st,
      ),
      403 => PermissionFailure(
        serverMessage: serverMessage,
        underlyingError: e,
        stackTrace: st,
      ),
      404 => NotFoundFailure(
        serverMessage: serverMessage,
        underlyingError: e,
        stackTrace: st,
      ),
      409 => ConflictFailure(
        serverMessage: serverMessage,
        underlyingError: e,
        stackTrace: st,
      ),
      422 => _fromValidationResponse(e, st),
      429 => RateLimitFailure(
        serverMessage: serverMessage,
        underlyingError: e,
        stackTrace: st,
      ),
      _ when (statusCode ?? 500) >= 500 => ServerFailure(
        statusCode: statusCode,
        serverMessage: serverMessage,
        underlyingError: e,
        stackTrace: st,
      ),
      _ => UnknownFailure(
        serverMessage: serverMessage,
        underlyingError: e,
        stackTrace: st,
      ),
    };
  }

  static String? _extractServerMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
      if (detail is Map<String, dynamic>) {
        final message = detail['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return null;
  }

  static AppFailure _fromBadRequest(DioException e, StackTrace? st) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final errorObj = data['error'];
      if (errorObj is Map<String, dynamic>) {
        final message = errorObj['message'];
        if (message is String && message.isNotEmpty) {
          return ValidationFailure(
            fieldMessages: {'detail': message},
            underlyingError: e,
            stackTrace: st,
          );
        }
      }
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        return ValidationFailure(
          fieldMessages: {'detail': detail},
          underlyingError: e,
          stackTrace: st,
        );
      }
    }
    return ValidationFailure(underlyingError: e, stackTrace: st);
  }

  /// Attempts to extract field-level validation errors from a 422 response.
  static AppFailure _fromValidationResponse(DioException e, StackTrace? st) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      // Common backend patterns: {"detail": {...}} or {"errors": {...}}
      final detail = data['detail'];
      final errors = data['errors'];

      if (detail is Map<String, dynamic>) {
        return ValidationFailure(
          fieldMessages: detail.map((k, v) => MapEntry(k, v.toString())),
          underlyingError: e,
          stackTrace: st,
        );
      }
      if (errors is Map<String, dynamic>) {
        return ValidationFailure(
          fieldMessages: errors.map((k, v) => MapEntry(k, v.toString())),
          underlyingError: e,
          stackTrace: st,
        );
      }
      if (detail is List) {
        final fieldMessages = <String, String>{};
        for (var i = 0; i < detail.length; i++) {
          final item = detail[i];
          if (item is Map<String, dynamic>) {
            final message = item['msg'];
            final text = (message is String && message.isNotEmpty)
                ? message
                : (item['type']?.toString() ?? 'detail_$i');
            fieldMessages[_validationFieldName(item['loc'], i)] = text;
          } else if (item != null) {
            fieldMessages['detail_$i'] = item.toString();
          }
        }
        if (fieldMessages.isNotEmpty) {
          return ValidationFailure(
            fieldMessages: fieldMessages,
            underlyingError: e,
            stackTrace: st,
          );
        }
      }
      if (detail is String) {
        return ValidationFailure(
          fieldMessages: {'detail': detail},
          underlyingError: e,
          stackTrace: st,
        );
      }
    }
    return ValidationFailure(underlyingError: e, stackTrace: st);
  }

  static String _validationFieldName(Object? location, int fallbackIndex) {
    if (location is List) {
      final parts = location
          .map((part) => part.toString())
          .where((part) => part.isNotEmpty && part != 'body')
          .toList(growable: false);
      if (parts.isNotEmpty) return parts.join('.');
    }
    if (location is String && location.isNotEmpty) return location;
    return 'detail_$fallbackIndex';
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
