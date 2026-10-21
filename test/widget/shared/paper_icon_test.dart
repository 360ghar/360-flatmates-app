import 'package:flatmates_app/features/shared/presentation/paper/paper_art.dart';
import 'package:flatmates_app/features/shared/presentation/paper/paper_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// [PaperIcon] paints its own op-codes, so it has to honour the ambient
/// [IconTheme] the way [Icon] does: size, colour and opacity.
void main() {
  CustomPainter painterFor(WidgetTester tester) => tester
      .widget<CustomPaint>(
        find.descendant(
          of: find.byType(PaperIcon),
          matching: find.byType(CustomPaint),
        ),
      )
      .painter!;

  Future<void> pumpIcon(WidgetTester tester, IconThemeData theme) =>
      tester.pumpWidget(
        MaterialApp(
          // Center: a route's own constraints are tight, which would stretch
          // the icon to the screen.
          home: Center(
            child: IconTheme(
              data: theme,
              child: const PaperIcon(PaperArt.navHome),
            ),
          ),
        ),
      );

  testWidgets('takes its size from the IconTheme', (tester) async {
    await pumpIcon(
      tester,
      const IconThemeData(color: Color(0xFFA94A2B), size: 30),
    );

    expect(tester.getSize(find.byType(PaperIcon)), const Size(30, 30));
  });

  testWidgets('fades with IconThemeData.opacity', (tester) async {
    await pumpIcon(
      tester,
      const IconThemeData(color: Color(0xFFA94A2B), opacity: 1),
    );
    final opaque = painterFor(tester);

    await pumpIcon(
      tester,
      const IconThemeData(color: Color(0xFFA94A2B), opacity: 0.5),
    );
    final faded = painterFor(tester);

    // A painter that ignores opacity would be identical and never repaint.
    expect(faded.shouldRepaint(opaque), isTrue);
  });
}
