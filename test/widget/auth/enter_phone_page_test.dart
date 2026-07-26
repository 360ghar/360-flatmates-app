import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/features/auth/presentation/enter_phone_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('EnterPhonePage', () {
    testWidgets('renders identifier input, Google button and continue CTA', (
      tester,
    ) async {
      final widget = await testableWidgetAsync(child: const EnterPhonePage());
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('enter_phone_input')), findsOneWidget);
      expect(find.byKey(const Key('auth_google_button')), findsOneWidget);
      expect(find.byKey(const Key('enter_phone_continue_cta')), findsOneWidget);
    });

    testWidgets(
      'terms checkbox is accepted by default and gates continue CTA',
      (tester) async {
        final widget = await testableWidgetAsync(child: const EnterPhonePage());
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final checkbox = tester.widget<Checkbox>(
          find.byKey(const Key('terms_checkbox')),
        );
        expect(checkbox.value, isTrue);

        // FlatmatesButton wraps a FilledButton; terms accepted → CTA enabled.
        final filledButton = find.descendant(
          of: find.byKey(const Key('enter_phone_continue_cta')),
          matching: find.byType(FilledButton),
        );
        final button = tester.widget<FilledButton>(filledButton);
        expect(button.onPressed, isNotNull);

        // Uncheck → CTA disabled.
        await tester.tap(find.byKey(const Key('terms_checkbox')));
        await tester.pumpAndSettle();
        final disabledButton = tester.widget<FilledButton>(filledButton);
        expect(disabledButton.onPressed, isNull);

        // Recheck → CTA enabled again.
        await tester.tap(find.byKey(const Key('terms_checkbox')));
        await tester.pumpAndSettle();
        final enabledButton = tester.widget<FilledButton>(filledButton);
        expect(enabledButton.onPressed, isNotNull);
      },
    );
  });
}
