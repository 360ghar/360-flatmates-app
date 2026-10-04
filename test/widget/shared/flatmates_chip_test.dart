import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_chip.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('FlatmatesChip action variant', () {
    testWidgets('is announced as a button with no selected state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      var taps = 0;
      bool? lastValue;
      await tester.pumpWidget(
        testableWidget(
          child: Scaffold(
            body: Center(
              child: FlatmatesChip(
                key: const Key('icebreaker_action'),
                label: 'Suggest a time',
                variant: FlatmatesChipVariant.action,
                onSelected: (value) {
                  taps++;
                  lastValue = value;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final data = tester
          .getSemantics(find.byKey(const Key('icebreaker_action')))
          .getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      // No selected state: assistive technology must not offer a filter.
      expect(data.flagsCollection.isSelected, Tristate.none);
      expect(data.flagsCollection.isInMutuallyExclusiveGroup, isFalse);
      expect(data.hasAction(SemanticsAction.tap), isTrue);

      await tester.tap(find.byKey(const Key('icebreaker_action')));
      await tester.pump();
      expect(taps, 1);
      expect(lastValue, isTrue);
      handle.dispose();
    });

    testWidgets('filter variant still announces a selected state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      var selected = false;
      await tester.pumpWidget(
        testableWidget(
          child: Scaffold(
            body: Center(
              child: FlatmatesChip(
                key: const Key('filter_chip'),
                label: 'Nearby',
                onSelected: (value) => selected = value,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final data = tester
          .getSemantics(find.byKey(const Key('filter_chip')))
          .getSemanticsData();
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.flagsCollection.isSelected, Tristate.isFalse);

      await tester.tap(find.byKey(const Key('filter_chip')));
      await tester.pump();
      expect(selected, isTrue);
      handle.dispose();
    });
  });
}
