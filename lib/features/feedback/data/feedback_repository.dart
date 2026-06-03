import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/endpoints.dart';
import '../../../core/providers.dart';
import '../domain/feedback_model.dart';

/// Submits in-app feedback (bug reports and feature requests) to the shared
/// backend via `POST /api/v1/bugs`.
///
/// The shared [ApiClient] already maps `DioException` → typed `AppFailure`
/// internally, so this repository does NOT catch/re-wrap errors — it lets the
/// `AppFailure` propagate to the calling page.
class FeedbackRepository {
  const FeedbackRepository(this._ref);

  final Ref _ref;

  /// Submits a bug report (`bug_type` defaults to `functionality_bug`).
  Future<void> submitBugReport({
    required String title,
    required String description,
    required String bugType,
    required String severity,
    String? appVersion,
    String? deviceInfo,
  }) {
    return _submit(
      BugReportRequest(
        source: 'mobile',
        bugType: bugType,
        severity: severity,
        title: title,
        description: description,
        appVersion: appVersion,
        deviceInfo: deviceInfo,
        tags: const ['flatmates'],
      ),
    );
  }

  /// Submits a feature request. This is simply a bug report with
  /// `bug_type: "feature_request"` — there is NO separate endpoint or flag.
  Future<void> submitFeatureRequest({
    required String title,
    required String description,
    String severity = 'medium',
    String? appVersion,
    String? deviceInfo,
  }) {
    return _submit(
      BugReportRequest(
        source: 'mobile',
        bugType: 'feature_request',
        severity: severity,
        title: title,
        description: description,
        appVersion: appVersion,
        deviceInfo: deviceInfo,
        tags: const ['flatmates'],
      ),
    );
  }

  Future<void> _submit(BugReportRequest request) async {
    await _ref
        .read(apiClientProvider)
        .post(FlatmatesEndpoints.bugs, data: request.toJson());
  }
}

final feedbackRepositoryProvider = Provider<FeedbackRepository>(
  (ref) => FeedbackRepository(ref),
);
