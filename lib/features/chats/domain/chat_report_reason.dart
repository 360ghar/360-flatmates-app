import '../../../core/domain/wire_enums.dart';
import '../../../l10n/gen/app_localizations.dart';

class ChatReportReason {
  const ChatReportReason({required this.value, this.catalogLabel});

  /// The `UserReportReason` wire value sent as `reason`.
  final String value;
  final String? catalogLabel;

  String resolvedLabel(AppLocalizations locale) {
    if (catalogLabel != null && catalogLabel!.isNotEmpty) {
      return catalogLabel!;
    }
    return switch (UserReportReason.fromJson(value)) {
      UserReportReason.fakeProfile => locale.reportFakeProfile,
      UserReportReason.spam => locale.reportSpam,
      UserReportReason.abuse => locale.reportAbuse,
      UserReportReason.inappropriate => locale.reportInappropriate,
      UserReportReason.other || null => locale.reportOther,
    };
  }

  /// The reasons the backend accepts, used when the bootstrap has no
  /// `flatmates_report_reasons` catalog. The ids are the `UserReportReason`
  /// wire values, which are also the seeded catalog ids.
  static List<ChatReportReason> defaults() {
    return [
      for (final reason in UserReportReason.values)
        ChatReportReason(value: reason.wire),
    ];
  }
}
