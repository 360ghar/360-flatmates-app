// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feedback_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

BugReportRequest _$BugReportRequestFromJson(Map<String, dynamic> json) {
  return _BugReportRequest.fromJson(json);
}

/// @nodoc
mixin _$BugReportRequest {
  String get source => throw _privateConstructorUsedError;
  @JsonKey(name: 'bug_type')
  String get bugType => throw _privateConstructorUsedError;
  String get severity => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'app_version', includeIfNull: false)
  String? get appVersion => throw _privateConstructorUsedError;
  @JsonKey(name: 'device_info', includeIfNull: false)
  String? get deviceInfo => throw _privateConstructorUsedError;
  @JsonKey(includeIfNull: false)
  List<String>? get tags => throw _privateConstructorUsedError;

  /// Serializes this BugReportRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BugReportRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BugReportRequestCopyWith<BugReportRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BugReportRequestCopyWith<$Res> {
  factory $BugReportRequestCopyWith(
    BugReportRequest value,
    $Res Function(BugReportRequest) then,
  ) = _$BugReportRequestCopyWithImpl<$Res, BugReportRequest>;
  @useResult
  $Res call({
    String source,
    @JsonKey(name: 'bug_type') String bugType,
    String severity,
    String title,
    String description,
    @JsonKey(name: 'app_version', includeIfNull: false) String? appVersion,
    @JsonKey(name: 'device_info', includeIfNull: false) String? deviceInfo,
    @JsonKey(includeIfNull: false) List<String>? tags,
  });
}

/// @nodoc
class _$BugReportRequestCopyWithImpl<$Res, $Val extends BugReportRequest>
    implements $BugReportRequestCopyWith<$Res> {
  _$BugReportRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BugReportRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = null,
    Object? bugType = null,
    Object? severity = null,
    Object? title = null,
    Object? description = null,
    Object? appVersion = freezed,
    Object? deviceInfo = freezed,
    Object? tags = freezed,
  }) {
    return _then(
      _value.copyWith(
            source: null == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String,
            bugType: null == bugType
                ? _value.bugType
                : bugType // ignore: cast_nullable_to_non_nullable
                      as String,
            severity: null == severity
                ? _value.severity
                : severity // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            appVersion: freezed == appVersion
                ? _value.appVersion
                : appVersion // ignore: cast_nullable_to_non_nullable
                      as String?,
            deviceInfo: freezed == deviceInfo
                ? _value.deviceInfo
                : deviceInfo // ignore: cast_nullable_to_non_nullable
                      as String?,
            tags: freezed == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BugReportRequestImplCopyWith<$Res>
    implements $BugReportRequestCopyWith<$Res> {
  factory _$$BugReportRequestImplCopyWith(
    _$BugReportRequestImpl value,
    $Res Function(_$BugReportRequestImpl) then,
  ) = __$$BugReportRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String source,
    @JsonKey(name: 'bug_type') String bugType,
    String severity,
    String title,
    String description,
    @JsonKey(name: 'app_version', includeIfNull: false) String? appVersion,
    @JsonKey(name: 'device_info', includeIfNull: false) String? deviceInfo,
    @JsonKey(includeIfNull: false) List<String>? tags,
  });
}

/// @nodoc
class __$$BugReportRequestImplCopyWithImpl<$Res>
    extends _$BugReportRequestCopyWithImpl<$Res, _$BugReportRequestImpl>
    implements _$$BugReportRequestImplCopyWith<$Res> {
  __$$BugReportRequestImplCopyWithImpl(
    _$BugReportRequestImpl _value,
    $Res Function(_$BugReportRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BugReportRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = null,
    Object? bugType = null,
    Object? severity = null,
    Object? title = null,
    Object? description = null,
    Object? appVersion = freezed,
    Object? deviceInfo = freezed,
    Object? tags = freezed,
  }) {
    return _then(
      _$BugReportRequestImpl(
        source: null == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String,
        bugType: null == bugType
            ? _value.bugType
            : bugType // ignore: cast_nullable_to_non_nullable
                  as String,
        severity: null == severity
            ? _value.severity
            : severity // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        appVersion: freezed == appVersion
            ? _value.appVersion
            : appVersion // ignore: cast_nullable_to_non_nullable
                  as String?,
        deviceInfo: freezed == deviceInfo
            ? _value.deviceInfo
            : deviceInfo // ignore: cast_nullable_to_non_nullable
                  as String?,
        tags: freezed == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BugReportRequestImpl implements _BugReportRequest {
  const _$BugReportRequestImpl({
    required this.source,
    @JsonKey(name: 'bug_type') required this.bugType,
    required this.severity,
    required this.title,
    required this.description,
    @JsonKey(name: 'app_version', includeIfNull: false) this.appVersion,
    @JsonKey(name: 'device_info', includeIfNull: false) this.deviceInfo,
    @JsonKey(includeIfNull: false) final List<String>? tags,
  }) : _tags = tags;

  factory _$BugReportRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$BugReportRequestImplFromJson(json);

  @override
  final String source;
  @override
  @JsonKey(name: 'bug_type')
  final String bugType;
  @override
  final String severity;
  @override
  final String title;
  @override
  final String description;
  @override
  @JsonKey(name: 'app_version', includeIfNull: false)
  final String? appVersion;
  @override
  @JsonKey(name: 'device_info', includeIfNull: false)
  final String? deviceInfo;
  final List<String>? _tags;
  @override
  @JsonKey(includeIfNull: false)
  List<String>? get tags {
    final value = _tags;
    if (value == null) return null;
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'BugReportRequest(source: $source, bugType: $bugType, severity: $severity, title: $title, description: $description, appVersion: $appVersion, deviceInfo: $deviceInfo, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BugReportRequestImpl &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.bugType, bugType) || other.bugType == bugType) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.appVersion, appVersion) ||
                other.appVersion == appVersion) &&
            (identical(other.deviceInfo, deviceInfo) ||
                other.deviceInfo == deviceInfo) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    source,
    bugType,
    severity,
    title,
    description,
    appVersion,
    deviceInfo,
    const DeepCollectionEquality().hash(_tags),
  );

  /// Create a copy of BugReportRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BugReportRequestImplCopyWith<_$BugReportRequestImpl> get copyWith =>
      __$$BugReportRequestImplCopyWithImpl<_$BugReportRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BugReportRequestImplToJson(this);
  }
}

abstract class _BugReportRequest implements BugReportRequest {
  const factory _BugReportRequest({
    required final String source,
    @JsonKey(name: 'bug_type') required final String bugType,
    required final String severity,
    required final String title,
    required final String description,
    @JsonKey(name: 'app_version', includeIfNull: false)
    final String? appVersion,
    @JsonKey(name: 'device_info', includeIfNull: false)
    final String? deviceInfo,
    @JsonKey(includeIfNull: false) final List<String>? tags,
  }) = _$BugReportRequestImpl;

  factory _BugReportRequest.fromJson(Map<String, dynamic> json) =
      _$BugReportRequestImpl.fromJson;

  @override
  String get source;
  @override
  @JsonKey(name: 'bug_type')
  String get bugType;
  @override
  String get severity;
  @override
  String get title;
  @override
  String get description;
  @override
  @JsonKey(name: 'app_version', includeIfNull: false)
  String? get appVersion;
  @override
  @JsonKey(name: 'device_info', includeIfNull: false)
  String? get deviceInfo;
  @override
  @JsonKey(includeIfNull: false)
  List<String>? get tags;

  /// Create a copy of BugReportRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BugReportRequestImplCopyWith<_$BugReportRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
