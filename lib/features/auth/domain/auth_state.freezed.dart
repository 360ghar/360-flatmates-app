// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AuthState {
  AuthStatus get status => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// The raw identifier (phone or email) the user is currently working with.
  String? get identifier => throw _privateConstructorUsedError;

  /// Whether the resolved identifier is already verified (drives the
  /// password-vs-OTP branch in the login state-machine).
  bool? get identifierVerified => throw _privateConstructorUsedError;

  /// Whether the resolved identifier maps to a phone or email channel.
  AuthChannel? get channel => throw _privateConstructorUsedError;

  /// Set after a successful email/phone OTP verify when the account has no
  /// password yet. While true, the router forces the mandatory
  /// (non-skippable) `/set-password` step before entering the app. Cleared
  /// once a password is set. Never set for Google/Apple (passwordless).
  bool get needsPassword => throw _privateConstructorUsedError;

  /// The current auth gate stage returned by the backend
  /// `/users/me/auth-state`.  Drives the redirect chain for profile
  /// completion and onboarding. Defaults to [AuthStage.active] so the
  /// gate is not triggered before the first fetch completes.
  AuthStage get authStage => throw _privateConstructorUsedError;

  /// Profile fields still missing (reported by the backend when
  /// `authStage == AuthStage.profileCompletion`).
  List<String> get missingProfileFields => throw _privateConstructorUsedError;

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthStateCopyWith<AuthState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthStateCopyWith<$Res> {
  factory $AuthStateCopyWith(AuthState value, $Res Function(AuthState) then) =
      _$AuthStateCopyWithImpl<$Res, AuthState>;
  @useResult
  $Res call({
    AuthStatus status,
    String? phone,
    String? errorMessage,
    String? identifier,
    bool? identifierVerified,
    AuthChannel? channel,
    bool needsPassword,
    AuthStage authStage,
    List<String> missingProfileFields,
  });
}

/// @nodoc
class _$AuthStateCopyWithImpl<$Res, $Val extends AuthState>
    implements $AuthStateCopyWith<$Res> {
  _$AuthStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? phone = freezed,
    Object? errorMessage = freezed,
    Object? identifier = freezed,
    Object? identifierVerified = freezed,
    Object? channel = freezed,
    Object? needsPassword = null,
    Object? authStage = null,
    Object? missingProfileFields = null,
  }) {
    return _then(
      _value.copyWith(
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as AuthStatus,
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
            identifier: freezed == identifier
                ? _value.identifier
                : identifier // ignore: cast_nullable_to_non_nullable
                      as String?,
            identifierVerified: freezed == identifierVerified
                ? _value.identifierVerified
                : identifierVerified // ignore: cast_nullable_to_non_nullable
                      as bool?,
            channel: freezed == channel
                ? _value.channel
                : channel // ignore: cast_nullable_to_non_nullable
                      as AuthChannel?,
            needsPassword: null == needsPassword
                ? _value.needsPassword
                : needsPassword // ignore: cast_nullable_to_non_nullable
                      as bool,
            authStage: null == authStage
                ? _value.authStage
                : authStage // ignore: cast_nullable_to_non_nullable
                      as AuthStage,
            missingProfileFields: null == missingProfileFields
                ? _value.missingProfileFields
                : missingProfileFields // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AuthStateImplCopyWith<$Res>
    implements $AuthStateCopyWith<$Res> {
  factory _$$AuthStateImplCopyWith(
    _$AuthStateImpl value,
    $Res Function(_$AuthStateImpl) then,
  ) = __$$AuthStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    AuthStatus status,
    String? phone,
    String? errorMessage,
    String? identifier,
    bool? identifierVerified,
    AuthChannel? channel,
    bool needsPassword,
    AuthStage authStage,
    List<String> missingProfileFields,
  });
}

/// @nodoc
class __$$AuthStateImplCopyWithImpl<$Res>
    extends _$AuthStateCopyWithImpl<$Res, _$AuthStateImpl>
    implements _$$AuthStateImplCopyWith<$Res> {
  __$$AuthStateImplCopyWithImpl(
    _$AuthStateImpl _value,
    $Res Function(_$AuthStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? phone = freezed,
    Object? errorMessage = freezed,
    Object? identifier = freezed,
    Object? identifierVerified = freezed,
    Object? channel = freezed,
    Object? needsPassword = null,
    Object? authStage = null,
    Object? missingProfileFields = null,
  }) {
    return _then(
      _$AuthStateImpl(
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as AuthStatus,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        identifier: freezed == identifier
            ? _value.identifier
            : identifier // ignore: cast_nullable_to_non_nullable
                  as String?,
        identifierVerified: freezed == identifierVerified
            ? _value.identifierVerified
            : identifierVerified // ignore: cast_nullable_to_non_nullable
                  as bool?,
        channel: freezed == channel
            ? _value.channel
            : channel // ignore: cast_nullable_to_non_nullable
                  as AuthChannel?,
        needsPassword: null == needsPassword
            ? _value.needsPassword
            : needsPassword // ignore: cast_nullable_to_non_nullable
                  as bool,
        authStage: null == authStage
            ? _value.authStage
            : authStage // ignore: cast_nullable_to_non_nullable
                  as AuthStage,
        missingProfileFields: null == missingProfileFields
            ? _value._missingProfileFields
            : missingProfileFields // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc

class _$AuthStateImpl extends _AuthState {
  const _$AuthStateImpl({
    required this.status,
    this.phone,
    this.errorMessage,
    this.identifier,
    this.identifierVerified,
    this.channel,
    this.needsPassword = false,
    this.authStage = AuthStage.active,
    final List<String> missingProfileFields = const [],
  }) : _missingProfileFields = missingProfileFields,
       super._();

  @override
  final AuthStatus status;
  @override
  final String? phone;
  @override
  final String? errorMessage;

  /// The raw identifier (phone or email) the user is currently working with.
  @override
  final String? identifier;

  /// Whether the resolved identifier is already verified (drives the
  /// password-vs-OTP branch in the login state-machine).
  @override
  final bool? identifierVerified;

  /// Whether the resolved identifier maps to a phone or email channel.
  @override
  final AuthChannel? channel;

  /// Set after a successful email/phone OTP verify when the account has no
  /// password yet. While true, the router forces the mandatory
  /// (non-skippable) `/set-password` step before entering the app. Cleared
  /// once a password is set. Never set for Google/Apple (passwordless).
  @override
  @JsonKey()
  final bool needsPassword;

  /// The current auth gate stage returned by the backend
  /// `/users/me/auth-state`.  Drives the redirect chain for profile
  /// completion and onboarding. Defaults to [AuthStage.active] so the
  /// gate is not triggered before the first fetch completes.
  @override
  @JsonKey()
  final AuthStage authStage;

  /// Profile fields still missing (reported by the backend when
  /// `authStage == AuthStage.profileCompletion`).
  final List<String> _missingProfileFields;

  /// Profile fields still missing (reported by the backend when
  /// `authStage == AuthStage.profileCompletion`).
  @override
  @JsonKey()
  List<String> get missingProfileFields {
    if (_missingProfileFields is EqualUnmodifiableListView)
      return _missingProfileFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_missingProfileFields);
  }

  @override
  String toString() {
    return 'AuthState(status: $status, phone: $phone, errorMessage: $errorMessage, identifier: $identifier, identifierVerified: $identifierVerified, channel: $channel, needsPassword: $needsPassword, authStage: $authStage, missingProfileFields: $missingProfileFields)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.identifier, identifier) ||
                other.identifier == identifier) &&
            (identical(other.identifierVerified, identifierVerified) ||
                other.identifierVerified == identifierVerified) &&
            (identical(other.channel, channel) || other.channel == channel) &&
            (identical(other.needsPassword, needsPassword) ||
                other.needsPassword == needsPassword) &&
            (identical(other.authStage, authStage) ||
                other.authStage == authStage) &&
            const DeepCollectionEquality().equals(
              other._missingProfileFields,
              _missingProfileFields,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    status,
    phone,
    errorMessage,
    identifier,
    identifierVerified,
    channel,
    needsPassword,
    authStage,
    const DeepCollectionEquality().hash(_missingProfileFields),
  );

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthStateImplCopyWith<_$AuthStateImpl> get copyWith =>
      __$$AuthStateImplCopyWithImpl<_$AuthStateImpl>(this, _$identity);
}

abstract class _AuthState extends AuthState {
  const factory _AuthState({
    required final AuthStatus status,
    final String? phone,
    final String? errorMessage,
    final String? identifier,
    final bool? identifierVerified,
    final AuthChannel? channel,
    final bool needsPassword,
    final AuthStage authStage,
    final List<String> missingProfileFields,
  }) = _$AuthStateImpl;
  const _AuthState._() : super._();

  @override
  AuthStatus get status;
  @override
  String? get phone;
  @override
  String? get errorMessage;

  /// The raw identifier (phone or email) the user is currently working with.
  @override
  String? get identifier;

  /// Whether the resolved identifier is already verified (drives the
  /// password-vs-OTP branch in the login state-machine).
  @override
  bool? get identifierVerified;

  /// Whether the resolved identifier maps to a phone or email channel.
  @override
  AuthChannel? get channel;

  /// Set after a successful email/phone OTP verify when the account has no
  /// password yet. While true, the router forces the mandatory
  /// (non-skippable) `/set-password` step before entering the app. Cleared
  /// once a password is set. Never set for Google/Apple (passwordless).
  @override
  bool get needsPassword;

  /// The current auth gate stage returned by the backend
  /// `/users/me/auth-state`.  Drives the redirect chain for profile
  /// completion and onboarding. Defaults to [AuthStage.active] so the
  /// gate is not triggered before the first fetch completes.
  @override
  AuthStage get authStage;

  /// Profile fields still missing (reported by the backend when
  /// `authStage == AuthStage.profileCompletion`).
  @override
  List<String> get missingProfileFields;

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthStateImplCopyWith<_$AuthStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
