import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/compatibility/compatibility_ring.dart';

import '../../helpers/test_helpers.dart';

/// The ring paints its progress with `Canvas.drawArc`; capture the sweep so
/// the test can tell a settled ring from one that is still animating.
Future<double?> _pumpRing(
  WidgetTester tester, {
  required bool reduceMotion,
}) async {
  double? sweep;
  await tester.pumpWidget(
    testableWidget(
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: const Scaffold(
            body: Center(child: CompatibilityRing(percentage: 80)),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  expect(
    find.byType(CompatibilityRing),
    paints..everything((method, arguments) {
      if (method == #drawArc) {
        sweep = arguments[2] as double;
      }
      return true;
    }),
  );
  return sweep;
}

void main() {
  const settledSweep = 2 * math.pi * 0.8;

  group('CompatibilityRing reduce motion', () {
    testWidgets('paints the settled arc on the first frame', (tester) async {
      final sweep = await _pumpRing(tester, reduceMotion: true);

      // No entrance animation is left running...
      expect(tester.binding.transientCallbackCount, 0);
      // ...and the arc is already at its final sweep.
      expect(sweep, closeTo(settledSweep, 0.01));
    });

    testWidgets('still animates when reduce motion is off', (tester) async {
      final sweep = await _pumpRing(tester, reduceMotion: false);

      expect(tester.binding.transientCallbackCount, greaterThan(0));
      expect(sweep, closeTo(0, 0.01));

      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('settles when the setting turns on while the ring is alive', (
      tester,
    ) async {
      await _pumpRing(tester, reduceMotion: false);
      // Mid-entrance.
      await tester.pump(const Duration(milliseconds: 60));

      final sweep = await _pumpRing(tester, reduceMotion: true);

      expect(tester.binding.transientCallbackCount, 0);
      expect(sweep, closeTo(settledSweep, 0.01));
    });
  });
}
