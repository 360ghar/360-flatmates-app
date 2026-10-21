import 'package:flatmates_app/core/theme/app_theme.dart';
import 'package:flatmates_app/features/shared/presentation/paper/paper_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Largest vertical translation applied inside the scene.
double _maxLayerShift(WidgetTester tester) {
  var max = 0.0;
  for (final t in tester.widgetList<Transform>(
    find.descendant(
      of: find.byType(PaperScene),
      matching: find.byType(Transform),
    ),
  )) {
    final dy = t.transform.getTranslation().y;
    if (dy > max) max = dy;
  }
  return max;
}

Future<ScrollController> _pump(
  WidgetTester tester, {
  required bool reduce,
}) async {
  final controller = ScrollController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.build(brightness: Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(
          body: ListView(
            controller: controller,
            children: [
              PaperScene.hero(parallax: controller),
              const SizedBox(height: 2000),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('scene layers shift with scroll (parallax)', (tester) async {
    final controller = await _pump(tester, reduce: false);
    expect(_maxLayerShift(tester), 0);
    controller.jumpTo(100);
    await tester.pump();
    expect(_maxLayerShift(tester), greaterThan(0));
  });

  testWidgets('reduce motion turns parallax off', (tester) async {
    final controller = await _pump(tester, reduce: true);
    controller.jumpTo(100);
    await tester.pump();
    expect(_maxLayerShift(tester), 0);
  });
}
