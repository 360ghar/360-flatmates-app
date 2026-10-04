import 'package:flatmates_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// [AppSpacing.scaled] sizes fixed-height boxes that hold text. Some of those
/// boxes wrap a 48 dp tap target (the 52 dp filter-chip strip), so the factor
/// is clamped to 1x..2x: below 1x the target would shrink under the minimum,
/// above 2x the text would clip.
void main() {
  late BuildContext captured;

  Future<void> pumpWithScale(WidgetTester tester, TextScaler scaler) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (outer) => MediaQuery(
            data: MediaQuery.of(outer).copyWith(textScaler: scaler),
            child: Builder(
              builder: (inner) {
                captured = inner;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('is unchanged at scale 1', (tester) async {
    await pumpWithScale(tester, TextScaler.noScaling);

    expect(AppSpacing.scaled(captured, 52), 52);
  });

  testWidgets('never shrinks below the base size', (tester) async {
    await pumpWithScale(tester, const TextScaler.linear(0.8));

    expect(AppSpacing.scaled(captured, 52), 52);
    expect(AppSpacing.scaled(captured, AppSpacing.xxl), AppSpacing.xxl);
  });

  testWidgets('grows with the text scale', (tester) async {
    await pumpWithScale(tester, const TextScaler.linear(1.5));

    expect(AppSpacing.scaled(captured, 52), 78);
  });

  testWidgets('caps at 2x', (tester) async {
    await pumpWithScale(tester, const TextScaler.linear(3));

    expect(AppSpacing.scaled(captured, 52), 104);
  });
}
