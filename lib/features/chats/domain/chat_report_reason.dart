import '../../../l10n/gen/app_localizations.dart';

class ChatReportReason {
  const ChatReportReason({required this.value, this.catalogLabel});

  final String value;
  final String? catalogLabel;

  String resolvedLabel(AppLocalizations locale) {
    if (catalogLabel != null && catalogLabel!.isNotEmpty) {
      return catalogLabel!;
    }
    return switch (value) {
      'fake_profile' => locale.reportFakeProfile,
      'spam' => locale.reportSpam,
      'inappropriate' => locale.reportInappropriate,
      'uncomfortable' => locale.reportUncomfortable,
      _ => locale.reportOther,
    };
  }

  static List<ChatReportReason> defaults() {
    return const [
      ChatReportReason(value: 'fake_profile'),
      ChatReportReason(value: 'spam'),
      ChatReportReason(value: 'inappropriate'),
      ChatReportReason(value: 'uncomfortable'),
      ChatReportReason(value: 'other'),
    ];
  }
}
