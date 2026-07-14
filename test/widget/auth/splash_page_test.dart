import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/features/auth/presentation/splash_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('SplashPage', () {
    testWidgets('renders without throwing', (tester) async {
      final widget = await testableWidgetAsync(child: const SplashPage());
      await tester.pumpWidget(widget);
      // Pump past the 800ms entrance animation without using pumpAndSettle
      // (the indeterminate LinearProgressIndicator never settles).
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SplashPage), findsOneWidget);
    });

    testWidgets('network error state does not overflow in landscape', (
      tester,
    ) async {
      // Use a small landscape viewport to catch overflow.
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final widget = await testableWidgetAsync(child: const SplashPage());
      await tester.pumpWidget(widget);
      await tester.pump(const Duration(seconds: 1));

      // No overflow errors should be thrown.
      expect(tester.takeException(), isNull);
      expect(find.byType(SplashPage), findsOneWidget);
    });

    testWidgets('renders progress indicator while loading', (tester) async {
      final widget = await testableWidgetAsync(child: const SplashPage());
      await tester.pumpWidget(widget);
      // Pump a few frames to let the staggered animation reach the progress
      // indicator interval (0.60–0.95 of 800ms ≈ 480–760ms).
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });
  });
}
