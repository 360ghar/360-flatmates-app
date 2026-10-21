import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_chrome_icon_button.dart';

import '../../helpers/test_helpers.dart';

Widget _host(Widget child) => testableWidget(
  child: Scaffold(body: Center(child: child)),
);

void main() {
  group('FlatmatesChromeIconButton tap target', () {
    testWidgets('outline style is at least 48 x 48 dp', (tester) async {
      await tester.pumpWidget(
        _host(
          FlatmatesChromeIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () {},
            tooltip: 'Back',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final target = find.descendant(
        of: find.byType(FlatmatesChromeIconButton),
        matching: find.byType(InkWell),
      );
      expect(target, findsOneWidget);
      final size = tester.getSize(target);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('filled style keeps 48 dp around its 32 dp disc', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FlatmatesChromeIconButton(
            icon: Icons.close_rounded,
            onPressed: () {},
            tooltip: 'Close',
            style: FlatmatesChromeIconStyle.filled,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final target = find.descendant(
        of: find.byType(FlatmatesChromeIconButton),
        matching: find.byType(InkWell),
      );
      final size = tester.getSize(target);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });
}
