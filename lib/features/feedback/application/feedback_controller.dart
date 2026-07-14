import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/feedback_repository.dart';

class FeedbackController {
  FeedbackController(this._repository);
  final FeedbackRepository _repository;

  Future<void> submitBugReport({
    required String title,
    required String description,
    required String bugType,
    required String severity,
    String? appVersion,
    String? deviceInfo,
  }) async {
    try {
      await _repository.submitBugReport(
        title: title,
        description: description,
        bugType: bugType,
        severity: severity,
        appVersion: appVersion,
        deviceInfo: deviceInfo,
      );
    } catch (e) {
      debugPrint('FeedbackController.submitBugReport: $e');
      rethrow;
    }
  }

  Future<void> submitFeatureRequest({
    required String title,
    required String description,
    String severity = 'medium',
    String? appVersion,
    String? deviceInfo,
  }) async {
    try {
      await _repository.submitFeatureRequest(
        title: title,
        description: description,
        severity: severity,
        appVersion: appVersion,
        deviceInfo: deviceInfo,
      );
    } catch (e) {
      debugPrint('FeedbackController.submitFeatureRequest: $e');
      rethrow;
    }
  }
}

final feedbackControllerProvider = Provider<FeedbackController>((ref) {
  return FeedbackController(ref.read(feedbackRepositoryProvider));
});
