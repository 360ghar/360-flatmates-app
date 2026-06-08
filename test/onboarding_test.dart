import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/onboarding/mode_selection_page.dart';
import 'package:flatmates_app/features/onboarding/basic_info_page.dart';
import 'package:flatmates_app/features/onboarding/onboarding_controller.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_ui.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('OnboardingController', () {
    test('completing splash moves a new user to mode selection', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await testAppPreferences;
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(onboardingControllerProvider.notifier);
      await controller.completeSplash();

      final state = container.read(onboardingControllerProvider);
      expect(state.step, OnboardingStep.modeSelection);
      expect(state.mode, isNull);
    });
  });

  group('ModeSelectionPage', () {
    testWidgets('renders exactly three mode options', (tester) async {
      await tester.pumpWidget(
        testableWidget(child: ModeSelectionPage(onModeSelected: (_) {})),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mode_room_poster')), findsOneWidget);
      expect(find.byKey(const Key('mode_co_hunter')), findsOneWidget);
      expect(find.byKey(const Key('mode_open_to_both')), findsOneWidget);
    });

    testWidgets('selecting a mode and pressing continue calls onModeSelected', (
      tester,
    ) async {
      String? selectedMode;
      await tester.pumpWidget(
        testableWidget(
          child: ModeSelectionPage(
            onModeSelected: (mode) => selectedMode = mode,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select a mode card
      await tester.tap(find.byKey(const Key('mode_co_hunter')));
      await tester.pumpAndSettle();

      // Continue button should now be enabled — tap it
      await tester.tap(find.byKey(const Key('mode_continue')));
      expect(selectedMode, 'co_hunter');
    });
  });

  group('BasicInfoPage', () {
    testWidgets('next button is disabled when fields are empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        testableWidget(child: BasicInfoPage(onNext: (_) {})),
      );
      await tester.pump();

      // Scroll to bottom to ensure the button is visible in ListView
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pump();

      final keyFinder = find.byKey(const Key('onboarding_basic_info_next'));
      expect(keyFinder, findsOneWidget);
      final button = tester.widget<FlatmatesButton>(keyFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets('next button is disabled when age is under 18', (tester) async {
      await tester.pumpWidget(
        testableWidget(child: BasicInfoPage(onNext: (_) {})),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('onboarding_name')),
        'John Doe',
      );
      await tester.enterText(find.byKey(const Key('onboarding_age')), '17');
      await tester.enterText(
        find.byKey(const Key('onboarding_profession')),
        'Engineer',
      );
      await tester.enterText(find.byKey(const Key('onboarding_city')), 'Delhi');
      await tester.pump();

      // Scroll to bottom
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pump();

      final button = tester.widget<FlatmatesButton>(
        find.byKey(const Key('onboarding_basic_info_next')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('next button is enabled when all fields valid and age >= 18', (
      tester,
    ) async {
      await tester.pumpWidget(
        testableWidget(child: BasicInfoPage(onNext: (_) {})),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('onboarding_name')),
        'Jane Doe',
      );
      await tester.enterText(find.byKey(const Key('onboarding_age')), '25');
      await tester.enterText(
        find.byKey(const Key('onboarding_profession')),
        'Designer',
      );
      await tester.enterText(
        find.byKey(const Key('onboarding_city')),
        'Mumbai',
      );
      await tester.pump();

      // Scroll to bottom
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pump();

      final button = tester.widget<FlatmatesButton>(
        find.byKey(const Key('onboarding_basic_info_next')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('age of exactly 18 is accepted', (tester) async {
      await tester.pumpWidget(
        testableWidget(child: BasicInfoPage(onNext: (_) {})),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('onboarding_name')),
        'Test User',
      );
      await tester.enterText(find.byKey(const Key('onboarding_age')), '18');
      await tester.enterText(
        find.byKey(const Key('onboarding_profession')),
        'Student',
      );
      await tester.enterText(
        find.byKey(const Key('onboarding_city')),
        'Bangalore',
      );
      await tester.pump();

      // Scroll to bottom
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pump();

      final button = tester.widget<FlatmatesButton>(
        find.byKey(const Key('onboarding_basic_info_next')),
      );
      expect(button.onPressed, isNotNull);
    });
  });
}
