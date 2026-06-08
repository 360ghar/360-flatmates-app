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
        underlyingError: e,
        stackTrace: st,
      ),
      DioExceptionType.connectionError => NetworkFailure(
        underlyingError: e,
        stackTrace: st,
      ),
      DioExceptionType.badResponse => _fromStatusCode(
        e.response?.statusCode,
        e,
        st,
      ),
      DioExceptionType.cancel => UnknownFailure(
        underlyingError: e,
        stackTrace: st,
      ),
      DioExceptionType.badCertificate => NetworkFailure(
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
      401 => AuthExpiredFailure(serverMessage: serverMessage, underlyingError: e, stackTrace: st),
      403 => PermissionFailure(serverMessage: serverMessage, underlyingError: e, stackTrace: st),
      404 => NotFoundFailure(serverMessage: serverMessage, underlyingError: e, stackTrace: st),
      409 => ConflictFailure(serverMessage: serverMessage, underlyingError: e, stackTrace: st),
      422 => _fromValidationResponse(e, st),
      429 => RateLimitFailure(serverMessage: serverMessage, underlyingError: e, stackTrace: st),
      _ when (statusCode ?? 500) >= 500 => ServerFailure(
        statusCode: statusCode,
        serverMessage: serverMessage,
        underlyingError: e,
        stackTrace: st,
      ),
      _ => UnknownFailure(serverMessage: serverMessage, underlyingError: e, stackTrace: st),
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

  static AppFailure _fromUnknown(DioException e, StackTrace? st) {
    final error = e.error;
    if (error is SocketException ||
        error is HandshakeException ||
        error is HttpException) {
      return NetworkFailure(underlyingError: e, stackTrace: st);
    }

    final message = '${e.message ?? ''} ${error ?? ''}'.toLowerCase();
    if (_looksLikeNetworkFailure(message)) {
      return NetworkFailure(underlyingError: e, stackTrace: st);
    }
    return UnknownFailure(underlyingError: e, stackTrace: st);
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
      'certificate',
      'tls',
      'ssl',
    ];

    return markers.any(message.contains);
  }
}
