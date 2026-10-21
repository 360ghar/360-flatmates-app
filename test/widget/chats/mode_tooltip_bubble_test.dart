import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/theme/app_theme.dart';
import 'package:flatmates_app/features/chats/presentation/widgets/mode_tooltip_bubble.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ModeTooltipBubble shadow', () {
    testWidgets('paints the e2 shadow at the token geometry', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: Theme(
            data: AppTheme.build(brightness: Brightness.light),
            child: const Scaffold(
              body: Center(
                child: ModeTooltipBubble(
                  label: 'Looking for a room + flatmate',
                  onTapKeepOpen: _noop,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final customPaint = find.descendant(
        of: find.byType(ModeTooltipBubble),
        matching: find.byType(CustomPaint),
      );
      expect(customPaint, findsOneWidget);
      final size = tester.getSize(customPaint);

      // Collect the painter's paths. (`BoxShadow.toPaint()` drops its
      // mask filter under `debugDisableShadows`, which flutter_test enables,
      // so the shadows are told apart from the opaque fill by alpha.)
      final shadowPaths = <Path>[];
      Path? fillPath;
      expect(
        find.byType(ModeTooltipBubble),
        paints..everything((method, arguments) {
          if (method == #drawPath) {
            final path = arguments[0] as Path;
            final paint = arguments[1] as Paint;
            if (paint.color.a == 1.0) {
              fillPath = path;
            } else {
              shadowPaths.add(path);
            }
          }
          return true;
        }),
      );

      expect(fillPath, isNotNull);
      expect(shadowPaths, hasLength(2), reason: 'e1 lip + e2 shadow');
      final e2 = shadowPaths[1];

      // The fill is the bubble itself.
      expect(
        fillPath!.contains(Offset(size.width / 2, size.height - 5)),
        isTrue,
      );

      // Inside the deflated e2 outline (bottom edge at height + 1).
      expect(e2.contains(Offset(size.width / 2, size.height - 5)), isTrue);
      // Outside it: this point is only inside the shadow when the token's
      // -2 spread is dropped (the un-deflated path reaches height + 3).
      expect(e2.contains(Offset(size.width / 2, size.height + 2)), isFalse);
    });
  });
}

void _noop() {}
