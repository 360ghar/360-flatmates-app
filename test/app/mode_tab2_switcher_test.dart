import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';
import 'package:flatmates_app/app/router/app_router.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/listings/post_hub_page.dart';
import 'package:flatmates_app/features/discover/map_view_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('ModeTab2Switcher', () {
    testWidgets('co_hunter mode shows MapViewPage (Explore)', (tester) async {
      final widget = await testableWidgetAsync(
        child: const Scaffold(body: ModeTab2Switcher()),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Default fakeBootstrapData has mode 'co_hunter' → should show
      // MapViewPage (Explore).
      expect(find.byType(MapViewPage), findsOneWidget);
      expect(find.byType(PostHubPage), findsNothing);
    });

    testWidgets('room_poster mode shows PostHubPage', (tester) async {
      final widget = await testableWidgetAsync(
        overrides: [
          bootstrapControllerProvider.overrideWith(
            () => _RoomPosterBootstrapController(),
          ),
        ],
        child: const Scaffold(body: ModeTab2Switcher()),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // room_poster mode → should show PostHubPage.
      expect(find.byType(PostHubPage), findsOneWidget);
    });
  });
}

/// A fake bootstrap controller that returns a room_poster profile.
class _RoomPosterBootstrapController extends FakeBootstrapController {
  @override
  Future<BootstrapData?> build() async {
    state = const AsyncValue.data(
      BootstrapData(
        profile: FlatmatesProfileModel(
          id: 1,
          fullName: 'Room Poster',
          mode: 'room_poster',
          profileStatus: 'active',
          onboardingCompleted: true,
        ),
      ),
    );
    return state.valueOrNull;
  }
}
