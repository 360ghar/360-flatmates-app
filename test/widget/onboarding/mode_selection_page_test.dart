import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/features/onboarding/mode_selection_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('ModeSelectionPage', () {
    testWidgets('renders exactly three mode options', (tester) async {
      String? selectedMode;
      final widget = await testableWidgetAsync(
        child: ModeSelectionPage(onModeSelected: (mode) => selectedMode = mode),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // The fake bootstrap data provides 3 modes: co_hunter, room_poster,
      // open_to_both.
      expect(find.byKey(const Key('mode_co_hunter')), findsOneWidget);
      expect(find.byKey(const Key('mode_room_poster')), findsOneWidget);
      expect(find.byKey(const Key('mode_open_to_both')), findsOneWidget);
    });

    testWidgets('selecting a mode and pressing continue calls onModeSelected', (
      tester,
    ) async {
      String? selectedMode;
      final widget = await testableWidgetAsync(
        child: ModeSelectionPage(onModeSelected: (mode) => selectedMode = mode),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Continue should be disabled before selecting a mode.
      final disabledButton = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(const Key('mode_continue')),
          matching: find.byType(FilledButton),
        ),
      );
      expect(disabledButton.onPressed, isNull);

      // Tap a mode card to select it.
      await tester.tap(find.byKey(const Key('mode_co_hunter')));
      await tester.pumpAndSettle();

      // Continue should now be enabled.
      final enabledButton = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(const Key('mode_continue')),
          matching: find.byType(FilledButton),
        ),
      );
      expect(enabledButton.onPressed, isNotNull);

      // Tap continue.
      await tester.tap(find.byKey(const Key('mode_continue')));
      await tester.pumpAndSettle();

      expect(selectedMode, 'co_hunter');
    });
  });
}
