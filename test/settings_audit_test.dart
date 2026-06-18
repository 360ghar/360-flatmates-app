import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/feedback/application/feedback_controller.dart';
import 'package:flatmates_app/features/feedback/data/feedback_repository.dart';
import 'package:flatmates_app/features/feedback/domain/feedback_model.dart';
import 'package:flatmates_app/features/feedback/presentation/feedback_form_page.dart';
import 'package:flatmates_app/features/settings/delete_account_page.dart';
import 'package:flatmates_app/features/settings/notification_settings_page.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_ui.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

import 'helpers/test_helpers.dart';

/// Wraps [child] in a ProviderScope + MaterialApp.router so pages that call
/// `context.pop()` (GoRouter) work under test.
Future<Widget> routedTestWidget({
  required Widget child,
  List<Override> overrides = const [],
}) async {
  final prefs = await testAppPreferences;
  // Start one level deep ("/host" → "/") so the page under test can `pop()`
  // back to a host route without "nothing to pop".
  final router = GoRouter(
    initialLocation: '/page',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('host')),
        routes: [GoRoute(path: 'page', builder: (_, _) => child)],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(fakeAppConfig()),
      appPreferencesProvider.overrideWithValue(prefs),
      authControllerProvider.overrideWith(() => FakeAuthController()),
      bootstrapControllerProvider.overrideWith(() => FakeBootstrapController()),
      ...overrides,
    ],
    child: MaterialApp.router(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    ),
  );
}

/// A [FeedbackRepository] that records the last submitted request and never
/// touches the network.
class _RecordingFeedbackRepository implements FeedbackRepository {
  BugReportRequest? lastBug;
  BugReportRequest? lastFeature;

  @override
  Future<void> submitBugReport({
    required String title,
    required String description,
    required String bugType,
    required String severity,
    String? appVersion,
    String? deviceInfo,
  }) async {
    lastBug = BugReportRequest(
      source: 'mobile',
      bugType: bugType,
      severity: severity,
      title: title,
      description: description,
    );
  }

  @override
  Future<void> submitFeatureRequest({
    required String title,
    required String description,
    String severity = 'medium',
    String? appVersion,
    String? deviceInfo,
  }) async {
    lastFeature = BugReportRequest(
      source: 'mobile',
      bugType: 'feature_request',
      severity: severity,
      title: title,
      description: description,
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('NotificationSettingsPage', () {
    testWidgets('renders all five notification toggles', (tester) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const NotificationSettingsPage()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsNWidgets(5));
      expect(find.byKey(const Key('notif_enable_all')), findsOneWidget);
      expect(find.byKey(const Key('notif_disable_all')), findsOneWidget);
    });

    testWidgets('Disable All turns every toggle off and shows a toast', (
      tester,
    ) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const NotificationSettingsPage()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('notif_disable_all')));
      await tester.pumpAndSettle();

      final switches = tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .toList();
      expect(switches.every((s) => s.value == false), isTrue);
      // Confirmation toast (SnackBar) surfaced.
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Enable All turns every toggle on', (tester) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const NotificationSettingsPage()),
      );
      await tester.pumpAndSettle();

      // First disable, then enable, to exercise both paths.
      await tester.tap(find.byKey(const Key('notif_disable_all')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notif_enable_all')));
      await tester.pumpAndSettle();

      final switches = tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .toList();
      expect(switches.every((s) => s.value == true), isTrue);
    });
  });

  group('DeleteAccountPage', () {
    testWidgets('confirm button is disabled until DELETE is typed', (
      tester,
    ) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const DeleteAccountPage()),
      );
      await tester.pumpAndSettle();

      FlatmatesButton confirmButton() => tester.widget<FlatmatesButton>(
        find.byKey(const Key('delete_account_confirm_button')),
      );

      // Initially disabled.
      expect(confirmButton().onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('delete_account_confirm_field')),
        'delete',
      );
      await tester.pumpAndSettle();

      // Case-insensitive match enables the button.
      expect(confirmButton().onPressed, isNotNull);
    });

    testWidgets('tapping confirm shows an irreversible-action dialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const DeleteAccountPage()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('delete_account_confirm_field')),
        'DELETE',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('delete_account_confirm_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.byKey(const Key('delete_account_dialog_confirm')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('delete_account_dialog_cancel')),
        findsOneWidget,
      );

      // Cancelling the dialog dismisses it without deleting.
      await tester.tap(find.byKey(const Key('delete_account_dialog_cancel')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('FeedbackFormPage', () {
    testWidgets('blocks submit when required fields are empty', (tester) async {
      final repo = _RecordingFeedbackRepository();
      await tester.pumpWidget(
        await routedTestWidget(
          child: const FeedbackFormPage(type: FeedbackType.bug),
          overrides: [
            feedbackControllerProvider.overrideWithValue(
              FeedbackController(repo),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('feedback_submit_button')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('feedback_submit_button')));
      await tester.pumpAndSettle();

      // Validation errors shown; nothing submitted.
      expect(repo.lastBug, isNull);
      expect(find.text('Please enter a title.'), findsOneWidget);
    });

    testWidgets('submits a feature request with valid input', (tester) async {
      final repo = _RecordingFeedbackRepository();
      await tester.pumpWidget(
        await routedTestWidget(
          child: const FeedbackFormPage(type: FeedbackType.feature),
          overrides: [
            feedbackControllerProvider.overrideWithValue(
              FeedbackController(repo),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('feedback_title_field')),
        'Add dark map style',
      );
      await tester.enterText(
        find.byKey(const Key('feedback_description_field')),
        'Please add a dark mode to the map view.',
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('feedback_submit_button')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('feedback_submit_button')));
      await tester.pumpAndSettle();

      expect(repo.lastFeature, isNotNull);
      expect(repo.lastFeature!.bugType, 'feature_request');
      expect(repo.lastFeature!.title, 'Add dark map style');
    });
  });
}
