import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/chats/presentation/widgets/chat_pre_message_area.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_chip.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ChatIcebreakerRow', () {
    testWidgets('suggested messages are action chips, not filters', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final submitted = <String>[];
      await tester.pumpWidget(
        testableWidget(
          child: Scaffold(
            body: ChatIcebreakerRow(
              icebreakers: const [
                'Hi! Is the room still available?',
                'When can I visit?',
              ],
              onSelected: submitted.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final chips = tester
          .widgetList<FlatmatesChip>(find.byType(FlatmatesChip))
          .toList();
      expect(chips, hasLength(2));
      expect(
        chips.every((chip) => chip.variant == FlatmatesChipVariant.action),
        isTrue,
      );

      // Announced as buttons with no selected state.
      final data = tester
          .getSemantics(find.byType(FlatmatesChip).first)
          .getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isSelected, Tristate.none);

      await tester.tap(find.text('When can I visit?'));
      await tester.pump();
      expect(submitted, ['When can I visit?']);

      handle.dispose();
    });
  });
}
