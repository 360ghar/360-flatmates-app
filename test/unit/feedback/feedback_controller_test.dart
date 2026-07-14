import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/feedback/application/feedback_controller.dart';
import 'package:flatmates_app/features/feedback/data/feedback_repository.dart';
import 'package:flatmates_app/features/feedback/domain/feedback_model.dart';

class _RecordingFeedbackRepository implements FeedbackRepository {
  _RecordingFeedbackRepository();

  BugReportRequest? lastBugRequest;
  BugReportRequest? lastFeatureRequest;

  @override
  Future<void> submitBugReport({
    required String title,
    required String description,
    required String bugType,
    required String severity,
    String? appVersion,
    String? deviceInfo,
  }) async {
    lastBugRequest = BugReportRequest(
      source: 'mobile',
      bugType: bugType,
      severity: severity,
      title: title,
      description: description,
      appVersion: appVersion,
      deviceInfo: deviceInfo,
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
    lastFeatureRequest = BugReportRequest(
      source: 'mobile',
      bugType: 'feature_request',
      severity: severity,
      title: title,
      description: description,
      appVersion: appVersion,
      deviceInfo: deviceInfo,
      tags: const ['flatmates'],
    );
  }
}

void main() {
  group('FeedbackController', () {
    test('submitBugReport calls repository with correct params', () async {
      final repo = _RecordingFeedbackRepository();
      final controller = FeedbackController(repo);

      await controller.submitBugReport(
        title: 'App crashes on login',
        description: 'The app crashes when I tap the login button',
        bugType: 'crash',
        severity: 'high',
        appVersion: '1.0.0',
        deviceInfo: 'iPhone 15',
      );

      expect(repo.lastBugRequest, isNotNull);
      expect(repo.lastBugRequest!.title, 'App crashes on login');
      expect(
        repo.lastBugRequest!.description,
        'The app crashes when I tap the login button',
      );
      expect(repo.lastBugRequest!.bugType, 'crash');
      expect(repo.lastBugRequest!.severity, 'high');
      expect(repo.lastBugRequest!.source, 'mobile');
      expect(repo.lastBugRequest!.appVersion, '1.0.0');
      expect(repo.lastBugRequest!.deviceInfo, 'iPhone 15');
      expect(repo.lastBugRequest!.tags, ['flatmates']);
    });

    test('submitFeatureRequest calls repository with correct params', () async {
      final repo = _RecordingFeedbackRepository();
      final controller = FeedbackController(repo);

      await controller.submitFeatureRequest(
        title: 'Add dark mode',
        description: 'It would be great to have a dark mode option',
        appVersion: '1.0.0',
        deviceInfo: 'Pixel 8',
      );

      expect(repo.lastFeatureRequest, isNotNull);
      expect(repo.lastFeatureRequest!.title, 'Add dark mode');
      expect(
        repo.lastFeatureRequest!.description,
        'It would be great to have a dark mode option',
      );
      expect(repo.lastFeatureRequest!.bugType, 'feature_request');
      expect(repo.lastFeatureRequest!.severity, 'medium');
      expect(repo.lastFeatureRequest!.source, 'mobile');
      expect(repo.lastFeatureRequest!.appVersion, '1.0.0');
      expect(repo.lastFeatureRequest!.deviceInfo, 'Pixel 8');
      expect(repo.lastFeatureRequest!.tags, ['flatmates']);
    });

    test(
      'submitFeatureRequest uses default severity when not provided',
      () async {
        final repo = _RecordingFeedbackRepository();
        final controller = FeedbackController(repo);

        await controller.submitFeatureRequest(
          title: 'Add filters',
          description: 'More filter options',
        );

        expect(repo.lastFeatureRequest!.severity, 'medium');
      },
    );

    test('submitBugReport rethrows on repository error', () async {
      final repo = _ThrowingFeedbackRepository();
      final controller = FeedbackController(repo);

      await expectLater(
        controller.submitBugReport(
          title: 'Bug',
          description: 'Desc',
          bugType: 'crash',
          severity: 'high',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('submitFeatureRequest rethrows on repository error', () async {
      final repo = _ThrowingFeedbackRepository();
      final controller = FeedbackController(repo);

      await expectLater(
        controller.submitFeatureRequest(title: 'Feature', description: 'Desc'),
        throwsA(isA<Exception>()),
      );
    });
  });
}

class _ThrowingFeedbackRepository implements FeedbackRepository {
  @override
  Future<void> submitBugReport({
    required String title,
    required String description,
    required String bugType,
    required String severity,
    String? appVersion,
    String? deviceInfo,
  }) async {
    throw Exception('Network error');
  }

  @override
  Future<void> submitFeatureRequest({
    required String title,
    required String description,
    String severity = 'medium',
    String? appVersion,
    String? deviceInfo,
  }) async {
    throw Exception('Network error');
  }
}
