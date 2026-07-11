import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/feedback/data/feedback_repository.dart';
import 'package:flatmates_app/features/feedback/domain/feedback_model.dart';
import 'package:flatmates_app/features/feedback/presentation/feedback_form_page.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

class _RecordingFeedbackRepository implements FeedbackRepository {
  BugReportRequest? lastRequest;

  @override
  Future<void> submitBugReport({
    required String title,
    required String description,
    required String bugType,
    required String severity,
    String? appVersion,
    String? deviceInfo,
  }) async {
    lastRequest = BugReportRequest(
      source: 'mobile',
      bugType: bugType,
      severity: severity,
      title: title,
      description: description,
      tags: const ['flatmates'],
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
    lastRequest = BugReportRequest(
      source: 'mobile',
      bugType: 'feature_request',
      severity: severity,
      title: title,
      description: description,
      tags: const ['flatmates'],
    );
  }
}

Future<Widget> _routedTestWidget({
  required Widget child,
  required _RecordingFeedbackRepository repo,
}) async {
  final prefs = await testAppPreferences;
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
      feedbackRepositoryProvider.overrideWithValue(repo),
      ...[],
    ],
    child: MaterialApp.router(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('FeedbackFormPage', () {
    testWidgets('blocks submit when required fields are empty', (tester) async {
      final repo = _RecordingFeedbackRepository();
      final widget = await _routedTestWidget(
        child: const FeedbackFormPage(type: FeedbackType.bug),
        repo: repo,
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Scroll down to the submit button (bug form is taller due to dropdowns).
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Tap submit with empty fields.
      await tester.tap(find.byKey(const Key('feedback_submit_button')));
      await tester.pumpAndSettle();

      // The repository should not have been called.
      expect(repo.lastRequest, isNull);
    });

    testWidgets('submits a feature request with valid input', (tester) async {
      final repo = _RecordingFeedbackRepository();
      final widget = await _routedTestWidget(
        child: const FeedbackFormPage(type: FeedbackType.feature),
        repo: repo,
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('feedback_title_field')),
        'Add dark mode',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('feedback_description_field')),
        'Please add a dark mode option',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('feedback_submit_button')));
      await tester.pumpAndSettle();

      expect(repo.lastRequest, isNotNull);
      expect(repo.lastRequest!.title, 'Add dark mode');
      expect(repo.lastRequest!.description, 'Please add a dark mode option');
      expect(repo.lastRequest!.bugType, 'feature_request');
    });

    testWidgets('submits a bug report with valid input', (tester) async {
      final repo = _RecordingFeedbackRepository();
      final widget = await _routedTestWidget(
        child: const FeedbackFormPage(type: FeedbackType.bug),
        repo: repo,
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('feedback_title_field')),
        'App crashes on login',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('feedback_description_field')),
        'The app crashes when I tap the login button',
      );
      await tester.pumpAndSettle();

      // Scroll down to the submit button (bug form is taller due to dropdowns).
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('feedback_submit_button')));
      await tester.pumpAndSettle();

      expect(repo.lastRequest, isNotNull);
      expect(repo.lastRequest!.title, 'App crashes on login');
      expect(
        repo.lastRequest!.description,
        'The app crashes when I tap the login button',
      );
      expect(repo.lastRequest!.bugType, 'functionality_bug');
      expect(repo.lastRequest!.severity, 'medium');
    });
  });
}
