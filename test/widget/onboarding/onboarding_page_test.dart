import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/features/onboarding/onboarding_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('OnboardingPage splash carousel', () {
    testWidgets('renders get started button', (tester) async {
      final widget = await testableWidgetAsync(child: const OnboardingPage());
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // The onboarding page starts at the splash carousel step.
      // Navigate to the last page to see the "get started" button.
      // First, verify the page renders without throwing.
      expect(find.byType(OnboardingPage), findsOneWidget);

      // The splash carousel has a "next" button on non-last pages.
      // Tap through to the last page.
      for (var i = 0; i < 3; i++) {
        final nextButton = find.byKey(const Key('onboarding_next'));
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton);
          await tester.pumpAndSettle();
        }
      }

      // On the last page, the "get started" button should be visible.
      expect(find.byKey(const Key('onboarding_get_started')), findsOneWidget);
    });

    testWidgets('renders skip button on non-last pages', (tester) async {
      final widget = await testableWidgetAsync(child: const OnboardingPage());
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // On the first page (not last), the skip button should be visible.
      expect(find.byKey(const Key('onboarding_skip')), findsOneWidget);
    });
  });
}
