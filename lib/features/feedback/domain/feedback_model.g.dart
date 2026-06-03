// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BugReportRequestImpl _$$BugReportRequestImplFromJson(
  Map<String, dynamic> json,
) => _$BugReportRequestImpl(
  source: json['source'] as String,
  bugType: json['bug_type'] as String,
  severity: json['severity'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  appVersion: json['app_version'] as String?,
  deviceInfo: json['device_info'] as String?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$$BugReportRequestImplToJson(
  _$BugReportRequestImpl instance,
) => <String, dynamic>{
  'source': instance.source,
  'bug_type': instance.bugType,
  'severity': instance.severity,
  'title': instance.title,
  'description': instance.description,
  if (instance.appVersion case final value?) 'app_version': value,
  if (instance.deviceInfo case final value?) 'device_info': value,
  if (instance.tags case final value?) 'tags': value,
};
