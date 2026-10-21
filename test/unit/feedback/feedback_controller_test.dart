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
    Map<String, dynamic>? deviceInfo,
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
    Map<String, dynamic>? deviceInfo,
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
  group('FeedbackController device context', () {
    test('a report carries the app version and the OS as an object', () async {
      final repo = _RecordingFeedbackRepository();
      final controller = FeedbackController(
        repo,
        deviceContext: () async => (
          appVersion: '1.4.2',
          deviceInfo: {
            'os': 'ios',
            'os_version': 'Version 26.5',
            'app_build': '57',
          },
        ),
      );

      await controller.submitBugReport(
        title: 'Crash',
        description: 'It crashed',
        bugType: 'crash',
        severity: 'high',
      );
      await controller.submitFeatureRequest(
        title: 'Dark mode',
        description: 'Please',
      );

      for (final request in [repo.lastBugRequest!, repo.lastFeatureRequest!]) {
        expect(request.appVersion, '1.4.2');
        // An object, never a string (a string is a 422).
        expect(request.deviceInfo, isA<Map<String, dynamic>>());
        expect(request.deviceInfo!['os'], 'ios');
      }
    });

    test('values the caller passes win over the device lookup', () async {
      final repo = _RecordingFeedbackRepository();
      final controller = FeedbackController(
        repo,
        deviceContext: () async =>
            (appVersion: '9.9.9', deviceInfo: {'os': 'x'}),
      );

      await controller.submitBugReport(
        title: 'Crash',
        description: 'It crashed',
        bugType: 'crash',
        severity: 'high',
        appVersion: '1.0.0',
        deviceInfo: {'os': 'android'},
      );

      expect(repo.lastBugRequest!.appVersion, '1.0.0');
      expect(repo.lastBugRequest!.deviceInfo, {'os': 'android'});
    });

    test('a failed lookup sends the report without them', () async {
      final repo = _RecordingFeedbackRepository();
      final controller = FeedbackController(
        repo,
        deviceContext: () async => null,
      );

      await controller.submitBugReport(
        title: 'Crash',
        description: 'It crashed',
        bugType: 'crash',
        severity: 'high',
      );

      expect(repo.lastBugRequest!.appVersion, isNull);
      expect(repo.lastBugRequest!.deviceInfo, isNull);
    });
  });

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
        deviceInfo: {'os': 'ios', 'model': 'iPhone 15'},
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
      expect(repo.lastBugRequest!.deviceInfo, {
        'os': 'ios',
        'model': 'iPhone 15',
      });
      expect(repo.lastBugRequest!.tags, ['flatmates']);
    });

    test('submitFeatureRequest calls repository with correct params', () async {
      final repo = _RecordingFeedbackRepository();
      final controller = FeedbackController(repo);

      await controller.submitFeatureRequest(
        title: 'Add dark mode',
        description: 'It would be great to have a dark mode option',
        appVersion: '1.0.0',
        deviceInfo: {'os': 'android', 'model': 'Pixel 8'},
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
      expect(repo.lastFeatureRequest!.deviceInfo, {
        'os': 'android',
        'model': 'Pixel 8',
      });
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
    Map<String, dynamic>? deviceInfo,
  }) async {
    throw Exception('Network error');
  }

  @override
  Future<void> submitFeatureRequest({
    required String title,
    required String description,
    String severity = 'medium',
    String? appVersion,
    Map<String, dynamic>? deviceInfo,
  }) async {
    throw Exception('Network error');
  }
}
