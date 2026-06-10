/// Typed application errors that flow through repositories and controllers.
///
/// Presentation layer uses [AppFailure.userMessage] for user-facing text via
/// l10n. Controllers and repositories throw or return these instead of raw
/// strings or DioExceptions.
sealed class AppFailure {
  const AppFailure({this.underlyingError, this.stackTrace});

  /// The original error, if any. Used for logging/crash reporting only.
  final Object? underlyingError;

  /// The original stack trace, if captured.
  final StackTrace? stackTrace;

  /// A short developer-readable label for logging.
  String get label;

  /// Returns a localized user-facing message.
  ///
  /// Uses [AppLocalizations] passed in so presentation doesn't need to
  /// know about error internals.
  String userMessage(UserMessageL10n l10n);
}

/// Network connectivity / timeout issues.
final class NetworkFailure extends AppFailure {
  const NetworkFailure({super.underlyingError, super.stackTrace});

  @override
  String get label => 'network';

  @override
  String userMessage(UserMessageL10n l10n) => l10n.errorNetwork;
}

/// Auth token expired or invalid. User must sign in again.
final class AuthExpiredFailure extends AppFailure {
  const AuthExpiredFailure({
    this.serverMessage,
    super.underlyingError,
    super.stackTrace,
  });

  final String? serverMessage;

  @override
  String get label => 'auth_expired';

  @override
  String userMessage(UserMessageL10n l10n) =>
      serverMessage ?? l10n.errorAuthExpired;
}

/// Server returned 5xx or unexpected error.
final class ServerFailure extends AppFailure {
  const ServerFailure({
    this.statusCode,
    this.serverMessage,
    super.underlyingError,
    super.stackTrace,
  });

  final int? statusCode;
  final String? serverMessage;

  @override
  String get label => 'server($statusCode)';

  @override
  String userMessage(UserMessageL10n l10n) => serverMessage ?? l10n.errorServer;
}

/// 403 Forbidden — user lacks permission.
final class PermissionFailure extends AppFailure {
  const PermissionFailure({
    this.serverMessage,
    super.underlyingError,
    super.stackTrace,
  });

  final String? serverMessage;

  @override
  String get label => 'permission';

  @override
  String userMessage(UserMessageL10n l10n) =>
      serverMessage ?? l10n.errorPermission;
}

/// 404 Not Found.
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({
    this.serverMessage,
    super.underlyingError,
    super.stackTrace,
  });

  final String? serverMessage;

  @override
  String get label => 'not_found';

  @override
  String userMessage(UserMessageL10n l10n) =>
      serverMessage ?? l10n.errorNotFound;
}

/// 422 / field-level validation errors from backend.
final class ValidationFailure extends AppFailure {
  const ValidationFailure({
    this.fieldMessages = const {},
    super.underlyingError,
    super.stackTrace,
  });

  /// Map of field name -> error message (already localized by backend or
  /// ready for display).
  final Map<String, String> fieldMessages;

  @override
  String get label => 'validation';

  @override
  String userMessage(UserMessageL10n l10n) {
    if (fieldMessages.isNotEmpty) {
      return fieldMessages.values.join('\n');
    }
    return l10n.errorValidation;
  }
}

/// Rate limited (429).
final class RateLimitFailure extends AppFailure {
  const RateLimitFailure({
    this.serverMessage,
    super.underlyingError,
    super.stackTrace,
  });

  final String? serverMessage;

  @override
  String get label => 'rate_limit';

  @override
  String userMessage(UserMessageL10n l10n) =>
      serverMessage ?? l10n.errorRateLimit;
}

/// Conflict (409).
final class ConflictFailure extends AppFailure {
  const ConflictFailure({
    this.serverMessage,
    super.underlyingError,
    super.stackTrace,
  });

  final String? serverMessage;

  @override
  String get label => 'conflict';

  @override
  String userMessage(UserMessageL10n l10n) =>
      serverMessage ?? l10n.errorConflict;
}

/// Upload-specific failures.
final class UploadFailure extends AppFailure {
  const UploadFailure({this.reason, super.underlyingError, super.stackTrace});

  final String? reason;

  @override
  String get label => 'upload';

  @override
  String userMessage(UserMessageL10n l10n) =>
      reason != null ? '${l10n.errorUpload}: $reason' : l10n.errorUpload;
}

/// Catch-all for unexpected errors.
final class UnknownFailure extends AppFailure {
  const UnknownFailure({
    this.serverMessage,
    super.underlyingError,
    super.stackTrace,
  });

  final String? serverMessage;

  @override
  String get label => 'unknown';

  @override
  String userMessage(UserMessageL10n l10n) =>
      serverMessage ?? l10n.errorUnknown;
}

/// Localized strings contract for error messages.
///
/// This decouples [AppFailure] from the generated [AppLocalizations] class,
/// so core/ doesn't import from features/l10n.
class UserMessageL10n {
  const UserMessageL10n({
    required this.errorNetwork,
    required this.errorAuthExpired,
    required this.errorServer,
    required this.errorPermission,
    required this.errorNotFound,
    required this.errorValidation,
    required this.errorRateLimit,
    required this.errorConflict,
    required this.errorUpload,
    required this.errorOtpInvalid,
    required this.errorAuthSessionMissing,
    required this.errorUnknown,
  });

  final String errorNetwork;
  final String errorAuthExpired;
  final String errorServer;
  final String errorPermission;
  final String errorNotFound;
  final String errorValidation;
  final String errorRateLimit;
  final String errorConflict;
  final String errorUpload;
  final String errorOtpInvalid;
  final String errorAuthSessionMissing;
  final String errorUnknown;
}
