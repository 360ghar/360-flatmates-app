// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'feedback_model.freezed.dart';
part 'feedback_model.g.dart';

/// Whether the in-app feedback form is reporting a bug or requesting a feature.
///
/// Both map to the same backend `POST /api/v1/bugs` endpoint; they differ only
/// by the `bug_type` value sent in the request body.
enum FeedbackType { bug, feature }

/// Request body for `POST /api/v1/bugs` (a GLOBAL endpoint, not under
/// `/flatmates`).
///
/// A feature request is simply a bug report with `bug_type: "feature_request"`
/// — there is no separate endpoint and no `feature_request` boolean.
@Freezed()
class BugReportRequest with _$BugReportRequest {
  const factory BugReportRequest({
    required String source,
    @JsonKey(name: 'bug_type') required String bugType,
    required String severity,
    required String title,
    required String description,
    @JsonKey(name: 'app_version', includeIfNull: false) String? appVersion,
    @JsonKey(name: 'device_info', includeIfNull: false) String? deviceInfo,
    @JsonKey(includeIfNull: false) List<String>? tags,
  }) = _BugReportRequest;

  factory BugReportRequest.fromJson(Map<String, dynamic> json) =>
      _$BugReportRequestFromJson(json);
}
