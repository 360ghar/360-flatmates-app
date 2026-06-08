import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/feedback_repository.dart';

class FeedbackController {
  FeedbackController(this._repository);
  final FeedbackRepository _repository;

  Future<bool> submitBugReport({
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
      return true;
    } catch (e) {
      debugPrint('FeedbackController.submitBugReport: $e');
      return false;
    }
  }

  Future<bool> submitFeatureRequest({
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
      return true;
    } catch (e) {
      debugPrint('FeedbackController.submitFeatureRequest: $e');
      return false;
    }
  }
}

final feedbackControllerProvider = Provider<FeedbackController>((ref) {
  return FeedbackController(ref.read(feedbackRepositoryProvider));
});
