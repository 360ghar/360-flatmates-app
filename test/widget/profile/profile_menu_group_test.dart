import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/profile/presentation/widgets/profile_menu_group.dart';

import '../../helpers/test_helpers.dart';

Widget _host({required bool reduceMotion}) => testableWidget(
  child: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: const Scaffold(
        body: StaggeredMenuGroup(delayIndex: 1, child: Text('group')),
      ),
    ),
  ),
);

/// The group's own rise — the route adds SlideTransitions of its own.
Finder get _rise => find.descendant(
  of: find.byType(StaggeredMenuGroup),
  matching: find.byType(SlideTransition),
);

void main() {
  group('StaggeredMenuGroup', () {
    testWidgets('drops the queued rise when reduced motion turns on', (
      tester,
    ) async {
      await tester.pumpWidget(_host(reduceMotion: false));
      // The controller exists and the rise is queued behind its delay
      // (300 ms + delayIndex * 40).
      expect(_rise, findsOneWidget);

      await tester.pumpWidget(_host(reduceMotion: true));
      expect(_rise, findsNothing);

      // Past the queued delay: the pending rise must not start.
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.binding.transientCallbackCount, 0);
      expect(find.text('group'), findsOneWidget);
    });

    testWidgets('still rises when reduced motion stays off', (tester) async {
      await tester.pumpWidget(_host(reduceMotion: false));
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.pumpAndSettle();
      expect(_rise, findsOneWidget);
      expect(find.text('group'), findsOneWidget);
    });
  });
}
