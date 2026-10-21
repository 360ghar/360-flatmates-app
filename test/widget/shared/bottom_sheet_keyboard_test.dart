import 'package:flatmates_app/core/theme/app_theme.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sheet content stays scrollable above the keyboard (M3)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667); // small phone
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(brightness: Brightness.light),
        home: MediaQuery(
          // Keyboard open: ~half the screen.
          data: const MediaQueryData(
            size: Size(375, 667),
            viewInsets: EdgeInsets.only(bottom: 320),
          ),
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: FlatmatesBottomSheet(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (var i = 0; i < 4; i++) ...[
                        const TextField(maxLines: 2),
                        const SizedBox(height: 60),
                      ],
                      const Text('Share Answers'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Share Answers'),
      100,
      scrollable: find
          .descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Share Answers'), findsOneWidget);
    // The sheet sits above the keyboard, not under it.
    expect(
      tester.getBottomLeft(find.byType(FlatmatesBottomSheet)).dy,
      lessThanOrEqualTo(667 - 320 + 1),
    );
  });
}
