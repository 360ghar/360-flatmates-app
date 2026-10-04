import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/features/shared/presentation/components.dart';

import '../../helpers/test_helpers.dart';

Widget _wrap(PreferredSizeWidget child) {
  return testableWidget(child: Scaffold(appBar: child));
}

void main() {
  group('FlatmatesHeader', () {
    testWidgets('back button keeps a 48 dp tap target in the leading slot', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(FlatmatesHeader.backTitle(title: 'Settings', onBack: () {})),
      );
      await tester.pumpAndSettle();

      // The leading slot (60) minus the caller padding (8) and the button's
      // own horizontal padding (2 + 2) must still leave 48 dp. At 56 the
      // button collapses to 44 dp, which is under the 48 dp minimum.
      final target = find.descendant(
        of: find.byKey(const Key('nav_back_button')),
        matching: find.byType(InkWell),
      );
      expect(target, findsOneWidget);
      final size = tester.getSize(target);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });
}
