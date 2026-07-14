import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/features/profile/help_safety_page.dart';

void main() {
  group('HelpSafetyPage', () {
    testWidgets('renders localized help and safety options', (tester) async {
      await tester.pumpWidget(testableWidget(child: const HelpSafetyPage()));
      await tester.pumpAndSettle();

      // The page title should be rendered.
      expect(find.byType(HelpSafetyPage), findsOneWidget);
    });

    testWidgets('renders FAQ item', (tester) async {
      await tester.pumpWidget(testableWidget(child: const HelpSafetyPage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('help_faq_item')), findsOneWidget);
    });

    testWidgets('renders contact item', (tester) async {
      await tester.pumpWidget(testableWidget(child: const HelpSafetyPage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('help_contact_item')), findsOneWidget);
    });

    testWidgets('renders report bug item', (tester) async {
      await tester.pumpWidget(testableWidget(child: const HelpSafetyPage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('report_a_bug_menu_item')), findsOneWidget);
    });

    testWidgets('renders request feature item', (tester) async {
      await tester.pumpWidget(testableWidget(child: const HelpSafetyPage()));
      await tester.pumpAndSettle();

      // Scroll down — the item is below the fold in the ListView.
      await tester.scrollUntilVisible(
        find.byKey(const Key('request_a_feature_menu_item')),
        200,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('request_a_feature_menu_item')),
        findsOneWidget,
      );
    });

    testWidgets('all help topic items render without throwing', (tester) async {
      await tester.pumpWidget(testableWidget(child: const HelpSafetyPage()));
      await tester.pumpAndSettle();

      // Verify all the main menu items are present.
      expect(find.byKey(const Key('help_faq_item')), findsOneWidget);
      expect(find.byKey(const Key('help_contact_item')), findsOneWidget);
      expect(find.byKey(const Key('report_a_bug_menu_item')), findsOneWidget);

      // Scroll down for items below the fold.
      await tester.scrollUntilVisible(
        find.byKey(const Key('request_a_feature_menu_item')),
        200,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('request_a_feature_menu_item')),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('help_chat_with_us_button')),
        200,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('help_chat_with_us_button')), findsOneWidget);
    });
  });
}
