import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/feedback_repository.dart';

/// What a report says about the app and the device: `app_version` and the
/// `device_info` object (`os`, `os_version`, `app_build`).
typedef FeedbackDeviceContext = ({
  String appVersion,
  Map<String, dynamic> deviceInfo,
});

/// Reads the version of the app and the OS. A failed lookup gives null, and the
/// report goes without them.
Future<FeedbackDeviceContext?> readFeedbackDeviceContext() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return (
      appVersion: info.version,
      deviceInfo: {
        'os': Platform.operatingSystem,
        'os_version': Platform.operatingSystemVersion,
        'app_build': info.buildNumber,
      },
    );
  } catch (e) {
    debugPrint('readFeedbackDeviceContext: $e');
    return null;
  }
}

class FeedbackController {
  FeedbackController(
    this._repository, {
    Future<FeedbackDeviceContext?> Function()? deviceContext,
  }) : _deviceContext = deviceContext ?? readFeedbackDeviceContext;

  final FeedbackRepository _repository;
  final Future<FeedbackDeviceContext?> Function() _deviceContext;

  Future<void> submitBugReport({
    required String title,
    required String description,
    required String bugType,
    required String severity,
    String? appVersion,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      final context = await _deviceContext();
      await _repository.submitBugReport(
        title: title,
        description: description,
        bugType: bugType,
        severity: severity,
        appVersion: appVersion ?? context?.appVersion,
        deviceInfo: deviceInfo ?? context?.deviceInfo,
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
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      final context = await _deviceContext();
      await _repository.submitFeatureRequest(
        title: title,
        description: description,
        severity: severity,
        appVersion: appVersion ?? context?.appVersion,
        deviceInfo: deviceInfo ?? context?.deviceInfo,
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
