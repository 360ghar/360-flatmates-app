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
    errorAuthExpired: errorAuthExpired,
    errorServer: errorServer,
    errorPermission: errorPermission,
    errorNotFound: errorNotFound,
    errorValidation: errorValidation,
    errorRateLimit: errorRateLimit,
    errorConflict: errorConflict,
    errorUpload: errorUpload,
    errorUnknown: errorUnknown,
  );
}
