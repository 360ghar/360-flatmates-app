import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/features/onboarding/basic_info_page.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_ui.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('BasicInfoPage', () {
    testWidgets('next button is disabled when fields are empty', (
      tester,
    ) async {
      // Use a tall viewport so all content is visible.
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final widget = await testableWidgetAsync(
        child: BasicInfoPage(onNext: (_) {}),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final button = tester.widget<FlatmatesButton>(
        find.byKey(const Key('onboarding_basic_info_next')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('next button is disabled when age is under 18', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final widget = await testableWidgetAsync(
        child: BasicInfoPage(onNext: (_) {}),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('onboarding_name')),
        'Test User',
      );
      await tester.enterText(find.byKey(const Key('onboarding_age')), '17');
      await tester.enterText(
        find.byKey(const Key('onboarding_profession')),
        'Engineer',
      );
      await tester.enterText(
        find.byKey(const Key('onboarding_city')),
        'Bangalore',
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FlatmatesButton>(
        find.byKey(const Key('onboarding_basic_info_next')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('next button is enabled when all fields valid and age >= 18', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final widget = await testableWidgetAsync(
        child: BasicInfoPage(onNext: (_) {}),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('onboarding_name')),
        'Test User',
      );
      await tester.enterText(find.byKey(const Key('onboarding_age')), '25');
      await tester.enterText(
        find.byKey(const Key('onboarding_profession')),
        'Engineer',
      );
      await tester.enterText(
        find.byKey(const Key('onboarding_city')),
        'Bangalore',
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FlatmatesButton>(
        find.byKey(const Key('onboarding_basic_info_next')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('age of exactly 18 is accepted', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final widget = await testableWidgetAsync(
        child: BasicInfoPage(onNext: (_) {}),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('onboarding_name')),
        'Test User',
      );
      await tester.enterText(find.byKey(const Key('onboarding_age')), '18');
      await tester.enterText(
        find.byKey(const Key('onboarding_profession')),
        'Engineer',
      );
      await tester.enterText(
        find.byKey(const Key('onboarding_city')),
        'Bangalore',
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FlatmatesButton>(
        find.byKey(const Key('onboarding_basic_info_next')),
      );
      expect(button.onPressed, isNotNull);
    });
  });
}
