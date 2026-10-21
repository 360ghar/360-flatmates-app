import '../../l10n/gen/app_localizations.dart';
import '../errors/app_failure.dart';

/// Creates a [UserMessageL10n] from the generated [AppLocalizations].
///
/// Usage:
/// ```dart
/// final l10n = AppLocalizations.of(context);
/// final message = failure.userMessage(l10n.toUserMessageL10n());
/// ```
extension AppLocalizationsX on AppLocalizations {
  UserMessageL10n toUserMessageL10n() => UserMessageL10n(
    errorNetwork: errorNetwork,
    errorTimeout: errorTimeout,
    errorCannotReachServer: errorCannotReachServer,
    errorAuthExpired: errorAuthExpired,
    errorAuth: errorAuth,
    errorServer: errorServer,
    errorServerWait: errorServerWait,
    errorPermission: errorPermission,
    errorNotFound: errorNotFound,
    errorValidation: errorValidation,
    errorRateLimit: errorRateLimit,
    errorRateLimitWait: errorRateLimitWait,
    errorConflict: errorConflict,
    errorUpload: errorUpload,
    errorOtpInvalid: errorOtpInvalid,
    errorAuthSessionMissing: errorAuthSessionMissing,
    errorUnknown: errorUnknown,
    codeMessages: {
      'PROFILE_NOT_FOUND': errorCodeProfileNotFound,
      'MATCH_NOT_FOUND': errorCodeMatchNotFound,
      'PROFILE_STATUS_LOCKED': errorCodeProfileStatusLocked,
      'LISTING_NOT_FOUND': errorCodeListingNotFound,
      'LISTING_STATUS_CONFLICT': listingStatusConflict,
      'BLOCK_NOT_FOUND': errorCodeBlockNotFound,
      'VISIT_CONFLICT': errorCodeVisitConflict,
      'VISIT_NOT_CANCELLABLE': errorCodeVisitNotCancellable,
      'VISIT_NOT_RESCHEDULABLE': errorCodeVisitNotReschedulable,
      'USER_INACTIVE': errorCodeUserInactive,
    },
  );
}

/// Resolves a `failure:`-prefixed error key (from [AuthController]) into a
/// localized user-facing message.
///
/// Returns [AppLocalizations.errorUnknown] for unrecognised keys.
String resolveAuthError(String? errorMessage, AppLocalizations l10n) {
  if (errorMessage == null || !errorMessage.startsWith('failure:')) {
    return l10n.errorUnknown;
  }
  final fullKey = errorMessage.substring(8);

  // Handle piped server messages: `failure:label|serverMessage`
  final parts = fullKey.split('|');
  final key = parts[0];
  if (parts.length > 1 && parts[1].isNotEmpty) {
    return parts.sublist(1).join('|');
  }

  // ServerFailure.label is 'server($statusCode)' — match any server(...) key.
  if (key == 'server' || key.startsWith('server(')) {
    return l10n.errorServer;
  }
  return switch (key) {
    'network' => l10n.errorNetwork,
    'network_timeout' => l10n.errorTimeout,
    'network_unreachable' => l10n.errorCannotReachServer,
    'auth_expired' => l10n.errorAuthExpired,
    'auth' => l10n.errorAuth,
    'permission' => l10n.errorPermission,
    'not_found' => l10n.errorNotFound,
    'validation' => l10n.errorValidation,
    'rate_limit' => l10n.errorRateLimit,
    'conflict' => l10n.errorConflict,
    'upload' => l10n.errorUpload,
    'invalid_credentials' => l10n.errorInvalidCredentials,
    'otp_invalid' => l10n.errorOtpInvalid,
    'auth_session_missing' => l10n.errorAuthSessionMissing,
    _ => l10n.errorUnknown,
  };
}
