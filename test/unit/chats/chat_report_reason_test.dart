import 'dart:ui' show Locale;

import 'package:flatmates_app/core/domain/wire_enums.dart';
import 'package:flatmates_app/features/chats/domain/chat_report_reason.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatReportReason.defaults', () {
    test('are exactly the reasons the backend accepts', () {
      final values = ChatReportReason.defaults().map((r) => r.value).toList();

      // `uncomfortable` is rejected by UserReportReason; `abuse` is accepted.
      expect(values, isNot(contains('uncomfortable')));
      expect(values, contains('abuse'));
      expect(values.toSet(), {
        for (final reason in UserReportReason.values) reason.wire,
      });
    });

    test('every default has a label', () async {
      final locale = await AppLocalizations.delegate.load(const Locale('en'));

      for (final reason in ChatReportReason.defaults()) {
        expect(reason.resolvedLabel(locale), isNotEmpty);
      }
      expect(
        const ChatReportReason(value: 'abuse').resolvedLabel(locale),
        locale.reportAbuse,
      );
    });
  });
}
