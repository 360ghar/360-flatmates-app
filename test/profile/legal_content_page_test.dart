import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/features/profile/legal_content_page.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: child,
);

void main() {
  group('LegalContentPage', () {
    testWidgets('renders the privacy policy markdown from assets', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegalContentPage(
            title: 'Privacy Policy',
            assetPath: 'assets/legal/privacy_policy.md',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Privacy Policy'), findsWidgets);
      // Markdown widget renders once the asset loads (no error/loading state).
      expect(find.byType(Markdown), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows a localized error when the asset is missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegalContentPage(
            title: 'Terms',
            assetPath: 'assets/legal/does_not_exist.md',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Markdown), findsNothing);
      expect(find.text('Could not load content.'), findsOneWidget);
    });
  });
}
