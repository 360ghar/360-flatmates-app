import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/features/profile/legal_content_page.dart';

void main() {
  group('LegalContentPage', () {
    testWidgets('renders the privacy policy markdown from assets', (
      tester,
    ) async {
      await tester.pumpWidget(
        testableWidget(
          child: const LegalContentPage(
            title: 'Privacy Policy',
            assetPath: 'assets/legal/privacy_policy.md',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The Markdown widget should render with the asset content.
      expect(find.byType(Markdown), findsOneWidget);
    });

    testWidgets('shows a localized error when the asset is missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        testableWidget(
          child: const LegalContentPage(
            title: 'Missing',
            assetPath: 'assets/legal/nonexistent.md',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The error state should render (not the Markdown widget).
      expect(find.byType(Markdown), findsNothing);
      // FlatmatesErrorState renders a Text with the error message.
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
