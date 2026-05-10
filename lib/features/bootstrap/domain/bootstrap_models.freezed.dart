// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bootstrap_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$CatalogEntryModel {
  String get key => throw _privateConstructorUsedError;
  int get version => throw _privateConstructorUsedError;
  Map<String, dynamic> get payload => throw _privateConstructorUsedError;

  /// Create a copy of CatalogEntryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CatalogEntryModelCopyWith<CatalogEntryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CatalogEntryModelCopyWith<$Res> {
  factory $CatalogEntryModelCopyWith(
    CatalogEntryModel value,
    $Res Function(CatalogEntryModel) then,
  ) = _$CatalogEntryModelCopyWithImpl<$Res, CatalogEntryModel>;
  @useResult
  $Res call({String key, int version, Map<String, dynamic> payload});
}

/// @nodoc
class _$CatalogEntryModelCopyWithImpl<$Res, $Val extends CatalogEntryModel>
    implements $CatalogEntryModelCopyWith<$Res> {
  _$CatalogEntryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CatalogEntryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? version = null,
    Object? payload = null,
  }) {
    return _then(
      _value.copyWith(
            key: null == key
                ? _value.key
                : key // ignore: cast_nullable_to_non_nullable
                      as String,
            version: null == version
                ? _value.version
                : version // ignore: cast_nullable_to_non_nullable
                      as int,
            payload: null == payload
                ? _value.payload
                : payload // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CatalogEntryModelImplCopyWith<$Res>
    implements $CatalogEntryModelCopyWith<$Res> {
  factory _$$CatalogEntryModelImplCopyWith(
    _$CatalogEntryModelImpl value,
    $Res Function(_$CatalogEntryModelImpl) then,
  ) = __$$CatalogEntryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String key, int version, Map<String, dynamic> payload});
}

/// @nodoc
class __$$CatalogEntryModelImplCopyWithImpl<$Res>
    extends _$CatalogEntryModelCopyWithImpl<$Res, _$CatalogEntryModelImpl>
    implements _$$CatalogEntryModelImplCopyWith<$Res> {
  __$$CatalogEntryModelImplCopyWithImpl(
    _$CatalogEntryModelImpl _value,
    $Res Function(_$CatalogEntryModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CatalogEntryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? version = null,
    Object? payload = null,
  }) {
    return _then(
      _$CatalogEntryModelImpl(
        key: null == key
            ? _value.key
            : key // ignore: cast_nullable_to_non_nullable
                  as String,
        version: null == version
            ? _value.version
            : version // ignore: cast_nullable_to_non_nullable
                  as int,
        payload: null == payload
            ? _value._payload
            : payload // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc

class _$CatalogEntryModelImpl extends _CatalogEntryModel {
  const _$CatalogEntryModelImpl({
    required this.key,
    this.version = 0,
    final Map<String, dynamic> payload = const {},
  }) : _payload = payload,
       super._();

  @override
  final String key;
  @override
  @JsonKey()
  final int version;
  final Map<String, dynamic> _payload;
  @override
  @JsonKey()
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  @override
  String toString() {
    return 'CatalogEntryModel(key: $key, version: $version, payload: $payload)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CatalogEntryModelImpl &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.version, version) || other.version == version) &&
            const DeepCollectionEquality().equals(other._payload, _payload));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    key,
    version,
    const DeepCollectionEquality().hash(_payload),
  );

  /// Create a copy of CatalogEntryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CatalogEntryModelImplCopyWith<_$CatalogEntryModelImpl> get copyWith =>
      __$$CatalogEntryModelImplCopyWithImpl<_$CatalogEntryModelImpl>(
        this,
        _$identity,
      );
}

abstract class _CatalogEntryModel extends CatalogEntryModel {
  const factory _CatalogEntryModel({
    required final String key,
    final int version,
    final Map<String, dynamic> payload,
  }) = _$CatalogEntryModelImpl;
  const _CatalogEntryModel._() : super._();

  @override
  String get key;
  @override
  int get version;
  @override
  Map<String, dynamic> get payload;

  /// Create a copy of CatalogEntryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CatalogEntryModelImplCopyWith<_$CatalogEntryModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$FlatmatesProfileModel {
  int get id => throw _privateConstructorUsedError;
  String? get fullName => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get profileImageUrl => throw _privateConstructorUsedError;
  String? get mode => throw _privateConstructorUsedError;
  String get profileStatus => throw _privateConstructorUsedError;
  bool get onboardingCompleted => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError;
  int? get age => throw _privateConstructorUsedError;
  String? get profession => throw _privateConstructorUsedError;
  double? get budgetMin => throw _privateConstructorUsedError;
  double? get budgetMax => throw _privateConstructorUsedError;
  String? get moveInTimeline => throw _privateConstructorUsedError;
  String? get city => throw _privateConstructorUsedError;
  String? get state => throw _privateConstructorUsedError;
  String? get locality => throw _privateConstructorUsedError;
  String? get sleepSchedule => throw _privateConstructorUsedError;
  String? get cleanliness => throw _privateConstructorUsedError;
  String? get foodHabits => throw _privateConstructorUsedError;
  String? get smokingDrinking => throw _privateConstructorUsedError;
  String? get guestsPolicy => throw _privateConstructorUsedError;
  String? get workStyle => throw _privateConstructorUsedError;
  String? get gender => throw _privateConstructorUsedError;
  String? get genderPreference => throw _privateConstructorUsedError;
  Map<String, dynamic> get preferences => throw _privateConstructorUsedError;

  /// Create a copy of FlatmatesProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FlatmatesProfileModelCopyWith<FlatmatesProfileModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FlatmatesProfileModelCopyWith<$Res> {
  factory $FlatmatesProfileModelCopyWith(
    FlatmatesProfileModel value,
    $Res Function(FlatmatesProfileModel) then,
  ) = _$FlatmatesProfileModelCopyWithImpl<$Res, FlatmatesProfileModel>;
  @useResult
  $Res call({
    int id,
    String? fullName,
    String? phone,
    String? email,
    String? profileImageUrl,
    String? mode,
    String profileStatus,
    bool onboardingCompleted,
    String? bio,
    int? age,
    String? profession,
    double? budgetMin,
    double? budgetMax,
    String? moveInTimeline,
    String? city,
    String? state,
    String? locality,
    String? sleepSchedule,
    String? cleanliness,
    String? foodHabits,
    String? smokingDrinking,
    String? guestsPolicy,
    String? workStyle,
    String? gender,
    String? genderPreference,
    Map<String, dynamic> preferences,
  });
}

/// @nodoc
class _$FlatmatesProfileModelCopyWithImpl<
  $Res,
  $Val extends FlatmatesProfileModel
>
    implements $FlatmatesProfileModelCopyWith<$Res> {
  _$FlatmatesProfileModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FlatmatesProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = freezed,
    Object? phone = freezed,
    Object? email = freezed,
    Object? profileImageUrl = freezed,
    Object? mode = freezed,
    Object? profileStatus = null,
    Object? onboardingCompleted = null,
    Object? bio = freezed,
    Object? age = freezed,
    Object? profession = freezed,
    Object? budgetMin = freezed,
    Object? budgetMax = freezed,
    Object? moveInTimeline = freezed,
    Object? city = freezed,
    Object? state = freezed,
    Object? locality = freezed,
    Object? sleepSchedule = freezed,
    Object? cleanliness = freezed,
    Object? foodHabits = freezed,
    Object? smokingDrinking = freezed,
    Object? guestsPolicy = freezed,
    Object? workStyle = freezed,
    Object? gender = freezed,
    Object? genderPreference = freezed,
    Object? preferences = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            fullName: freezed == fullName
                ? _value.fullName
                : fullName // ignore: cast_nullable_to_non_nullable
                      as String?,
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
            profileImageUrl: freezed == profileImageUrl
                ? _value.profileImageUrl
                : profileImageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            mode: freezed == mode
                ? _value.mode
                : mode // ignore: cast_nullable_to_non_nullable
                      as String?,
            profileStatus: null == profileStatus
                ? _value.profileStatus
                : profileStatus // ignore: cast_nullable_to_non_nullable
                      as String,
            onboardingCompleted: null == onboardingCompleted
                ? _value.onboardingCompleted
                : onboardingCompleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            bio: freezed == bio
                ? _value.bio
                : bio // ignore: cast_nullable_to_non_nullable
                      as String?,
            age: freezed == age
                ? _value.age
                : age // ignore: cast_nullable_to_non_nullable
                      as int?,
            profession: freezed == profession
                ? _value.profession
                : profession // ignore: cast_nullable_to_non_nullable
                      as String?,
            budgetMin: freezed == budgetMin
                ? _value.budgetMin
                : budgetMin // ignore: cast_nullable_to_non_nullable
                      as double?,
            budgetMax: freezed == budgetMax
                ? _value.budgetMax
                : budgetMax // ignore: cast_nullable_to_non_nullable
                      as double?,
            moveInTimeline: freezed == moveInTimeline
                ? _value.moveInTimeline
                : moveInTimeline // ignore: cast_nullable_to_non_nullable
                      as String?,
            city: freezed == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String?,
            state: freezed == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                      as String?,
            locality: freezed == locality
                ? _value.locality
                : locality // ignore: cast_nullable_to_non_nullable
                      as String?,
            sleepSchedule: freezed == sleepSchedule
                ? _value.sleepSchedule
                : sleepSchedule // ignore: cast_nullable_to_non_nullable
                      as String?,
            cleanliness: freezed == cleanliness
                ? _value.cleanliness
                : cleanliness // ignore: cast_nullable_to_non_nullable
                      as String?,
            foodHabits: freezed == foodHabits
                ? _value.foodHabits
                : foodHabits // ignore: cast_nullable_to_non_nullable
                      as String?,
            smokingDrinking: freezed == smokingDrinking
                ? _value.smokingDrinking
                : smokingDrinking // ignore: cast_nullable_to_non_nullable
                      as String?,
            guestsPolicy: freezed == guestsPolicy
                ? _value.guestsPolicy
                : guestsPolicy // ignore: cast_nullable_to_non_nullable
                      as String?,
            workStyle: freezed == workStyle
                ? _value.workStyle
                : workStyle // ignore: cast_nullable_to_non_nullable
                      as String?,
            gender: freezed == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as String?,
            genderPreference: freezed == genderPreference
                ? _value.genderPreference
                : genderPreference // ignore: cast_nullable_to_non_nullable
                      as String?,
            preferences: null == preferences
                ? _value.preferences
                : preferences // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FlatmatesProfileModelImplCopyWith<$Res>
    implements $FlatmatesProfileModelCopyWith<$Res> {
  factory _$$FlatmatesProfileModelImplCopyWith(
    _$FlatmatesProfileModelImpl value,
    $Res Function(_$FlatmatesProfileModelImpl) then,
  ) = __$$FlatmatesProfileModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String? fullName,
    String? phone,
    String? email,
    String? profileImageUrl,
    String? mode,
    String profileStatus,
    bool onboardingCompleted,
    String? bio,
    int? age,
    String? profession,
    double? budgetMin,
    double? budgetMax,
    String? moveInTimeline,
    String? city,
    String? state,
    String? locality,
    String? sleepSchedule,
    String? cleanliness,
    String? foodHabits,
    String? smokingDrinking,
    String? guestsPolicy,
    String? workStyle,
    String? gender,
    String? genderPreference,
    Map<String, dynamic> preferences,
  });
}

/// @nodoc
class __$$FlatmatesProfileModelImplCopyWithImpl<$Res>
    extends
        _$FlatmatesProfileModelCopyWithImpl<$Res, _$FlatmatesProfileModelImpl>
    implements _$$FlatmatesProfileModelImplCopyWith<$Res> {
  __$$FlatmatesProfileModelImplCopyWithImpl(
    _$FlatmatesProfileModelImpl _value,
    $Res Function(_$FlatmatesProfileModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FlatmatesProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = freezed,
    Object? phone = freezed,
    Object? email = freezed,
    Object? profileImageUrl = freezed,
    Object? mode = freezed,
    Object? profileStatus = null,
    Object? onboardingCompleted = null,
    Object? bio = freezed,
    Object? age = freezed,
    Object? profession = freezed,
    Object? budgetMin = freezed,
    Object? budgetMax = freezed,
    Object? moveInTimeline = freezed,
    Object? city = freezed,
    Object? state = freezed,
    Object? locality = freezed,
    Object? sleepSchedule = freezed,
    Object? cleanliness = freezed,
    Object? foodHabits = freezed,
    Object? smokingDrinking = freezed,
    Object? guestsPolicy = freezed,
    Object? workStyle = freezed,
    Object? gender = freezed,
    Object? genderPreference = freezed,
    Object? preferences = null,
  }) {
    return _then(
      _$FlatmatesProfileModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        fullName: freezed == fullName
            ? _value.fullName
            : fullName // ignore: cast_nullable_to_non_nullable
                  as String?,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
        profileImageUrl: freezed == profileImageUrl
            ? _value.profileImageUrl
            : profileImageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        mode: freezed == mode
            ? _value.mode
            : mode // ignore: cast_nullable_to_non_nullable
                  as String?,
        profileStatus: null == profileStatus
            ? _value.profileStatus
            : profileStatus // ignore: cast_nullable_to_non_nullable
                  as String,
        onboardingCompleted: null == onboardingCompleted
            ? _value.onboardingCompleted
            : onboardingCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        bio: freezed == bio
            ? _value.bio
            : bio // ignore: cast_nullable_to_non_nullable
                  as String?,
        age: freezed == age
            ? _value.age
            : age // ignore: cast_nullable_to_non_nullable
                  as int?,
        profession: freezed == profession
            ? _value.profession
            : profession // ignore: cast_nullable_to_non_nullable
                  as String?,
        budgetMin: freezed == budgetMin
            ? _value.budgetMin
            : budgetMin // ignore: cast_nullable_to_non_nullable
                  as double?,
        budgetMax: freezed == budgetMax
            ? _value.budgetMax
            : budgetMax // ignore: cast_nullable_to_non_nullable
                  as double?,
        moveInTimeline: freezed == moveInTimeline
            ? _value.moveInTimeline
            : moveInTimeline // ignore: cast_nullable_to_non_nullable
                  as String?,
        city: freezed == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String?,
        state: freezed == state
            ? _value.state
            : state // ignore: cast_nullable_to_non_nullable
                  as String?,
        locality: freezed == locality
            ? _value.locality
            : locality // ignore: cast_nullable_to_non_nullable
                  as String?,
        sleepSchedule: freezed == sleepSchedule
            ? _value.sleepSchedule
            : sleepSchedule // ignore: cast_nullable_to_non_nullable
                  as String?,
        cleanliness: freezed == cleanliness
            ? _value.cleanliness
            : cleanliness // ignore: cast_nullable_to_non_nullable
                  as String?,
        foodHabits: freezed == foodHabits
            ? _value.foodHabits
            : foodHabits // ignore: cast_nullable_to_non_nullable
                  as String?,
        smokingDrinking: freezed == smokingDrinking
            ? _value.smokingDrinking
            : smokingDrinking // ignore: cast_nullable_to_non_nullable
                  as String?,
        guestsPolicy: freezed == guestsPolicy
            ? _value.guestsPolicy
            : guestsPolicy // ignore: cast_nullable_to_non_nullable
                  as String?,
        workStyle: freezed == workStyle
            ? _value.workStyle
            : workStyle // ignore: cast_nullable_to_non_nullable
                  as String?,
        gender: freezed == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as String?,
        genderPreference: freezed == genderPreference
            ? _value.genderPreference
            : genderPreference // ignore: cast_nullable_to_non_nullable
                  as String?,
        preferences: null == preferences
            ? _value._preferences
            : preferences // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc

class _$FlatmatesProfileModelImpl extends _FlatmatesProfileModel {
  const _$FlatmatesProfileModelImpl({
    required this.id,
    this.fullName,
    this.phone,
    this.email,
    this.profileImageUrl,
    this.mode,
    this.profileStatus = 'draft',
    this.onboardingCompleted = false,
    this.bio,
    this.age,
    this.profession,
    this.budgetMin,
    this.budgetMax,
    this.moveInTimeline,
    this.city,
    this.state,
    this.locality,
    this.sleepSchedule,
    this.cleanliness,
    this.foodHabits,
    this.smokingDrinking,
    this.guestsPolicy,
    this.workStyle,
    this.gender,
    this.genderPreference,
    final Map<String, dynamic> preferences = const {},
  }) : _preferences = preferences,
       super._();

  @override
  final int id;
  @override
  final String? fullName;
  @override
  final String? phone;
  @override
  final String? email;
  @override
  final String? profileImageUrl;
  @override
  final String? mode;
  @override
  @JsonKey()
  final String profileStatus;
  @override
  @JsonKey()
  final bool onboardingCompleted;
  @override
  final String? bio;
  @override
  final int? age;
  @override
  final String? profession;
  @override
  final double? budgetMin;
  @override
  final double? budgetMax;
  @override
  final String? moveInTimeline;
  @override
  final String? city;
  @override
  final String? state;
  @override
  final String? locality;
  @override
  final String? sleepSchedule;
  @override
  final String? cleanliness;
  @override
  final String? foodHabits;
  @override
  final String? smokingDrinking;
  @override
  final String? guestsPolicy;
  @override
  final String? workStyle;
  @override
  final String? gender;
  @override
  final String? genderPreference;
  final Map<String, dynamic> _preferences;
  @override
  @JsonKey()
  Map<String, dynamic> get preferences {
    if (_preferences is EqualUnmodifiableMapView) return _preferences;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_preferences);
  }

  @override
  String toString() {
    return 'FlatmatesProfileModel(id: $id, fullName: $fullName, phone: $phone, email: $email, profileImageUrl: $profileImageUrl, mode: $mode, profileStatus: $profileStatus, onboardingCompleted: $onboardingCompleted, bio: $bio, age: $age, profession: $profession, budgetMin: $budgetMin, budgetMax: $budgetMax, moveInTimeline: $moveInTimeline, city: $city, state: $state, locality: $locality, sleepSchedule: $sleepSchedule, cleanliness: $cleanliness, foodHabits: $foodHabits, smokingDrinking: $smokingDrinking, guestsPolicy: $guestsPolicy, workStyle: $workStyle, gender: $gender, genderPreference: $genderPreference, preferences: $preferences)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FlatmatesProfileModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.profileImageUrl, profileImageUrl) ||
                other.profileImageUrl == profileImageUrl) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.profileStatus, profileStatus) ||
                other.profileStatus == profileStatus) &&
            (identical(other.onboardingCompleted, onboardingCompleted) ||
                other.onboardingCompleted == onboardingCompleted) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.age, age) || other.age == age) &&
            (identical(other.profession, profession) ||
                other.profession == profession) &&
            (identical(other.budgetMin, budgetMin) ||
                other.budgetMin == budgetMin) &&
            (identical(other.budgetMax, budgetMax) ||
                other.budgetMax == budgetMax) &&
            (identical(other.moveInTimeline, moveInTimeline) ||
                other.moveInTimeline == moveInTimeline) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.locality, locality) ||
                other.locality == locality) &&
            (identical(other.sleepSchedule, sleepSchedule) ||
                other.sleepSchedule == sleepSchedule) &&
            (identical(other.cleanliness, cleanliness) ||
                other.cleanliness == cleanliness) &&
            (identical(other.foodHabits, foodHabits) ||
                other.foodHabits == foodHabits) &&
            (identical(other.smokingDrinking, smokingDrinking) ||
                other.smokingDrinking == smokingDrinking) &&
            (identical(other.guestsPolicy, guestsPolicy) ||
                other.guestsPolicy == guestsPolicy) &&
            (identical(other.workStyle, workStyle) ||
                other.workStyle == workStyle) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.genderPreference, genderPreference) ||
                other.genderPreference == genderPreference) &&
            const DeepCollectionEquality().equals(
              other._preferences,
              _preferences,
            ));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    fullName,
    phone,
    email,
    profileImageUrl,
    mode,
    profileStatus,
    onboardingCompleted,
    bio,
    age,
    profession,
    budgetMin,
    budgetMax,
    moveInTimeline,
    city,
    state,
    locality,
    sleepSchedule,
    cleanliness,
    foodHabits,
    smokingDrinking,
    guestsPolicy,
    workStyle,
    gender,
    genderPreference,
    const DeepCollectionEquality().hash(_preferences),
  ]);

  /// Create a copy of FlatmatesProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FlatmatesProfileModelImplCopyWith<_$FlatmatesProfileModelImpl>
  get copyWith =>
      __$$FlatmatesProfileModelImplCopyWithImpl<_$FlatmatesProfileModelImpl>(
        this,
        _$identity,
      );
}

abstract class _FlatmatesProfileModel extends FlatmatesProfileModel {
  const factory _FlatmatesProfileModel({
    required final int id,
    final String? fullName,
    final String? phone,
    final String? email,
    final String? profileImageUrl,
    final String? mode,
    final String profileStatus,
    final bool onboardingCompleted,
    final String? bio,
    final int? age,
    final String? profession,
    final double? budgetMin,
    final double? budgetMax,
    final String? moveInTimeline,
    final String? city,
    final String? state,
    final String? locality,
    final String? sleepSchedule,
    final String? cleanliness,
    final String? foodHabits,
    final String? smokingDrinking,
    final String? guestsPolicy,
    final String? workStyle,
    final String? gender,
    final String? genderPreference,
    final Map<String, dynamic> preferences,
  }) = _$FlatmatesProfileModelImpl;
  const _FlatmatesProfileModel._() : super._();

  @override
  int get id;
  @override
  String? get fullName;
  @override
  String? get phone;
  @override
  String? get email;
  @override
  String? get profileImageUrl;
  @override
  String? get mode;
  @override
  String get profileStatus;
  @override
  bool get onboardingCompleted;
  @override
  String? get bio;
  @override
  int? get age;
  @override
  String? get profession;
  @override
  double? get budgetMin;
  @override
  double? get budgetMax;
  @override
  String? get moveInTimeline;
  @override
  String? get city;
  @override
  String? get state;
  @override
  String? get locality;
  @override
  String? get sleepSchedule;
  @override
  String? get cleanliness;
  @override
  String? get foodHabits;
  @override
  String? get smokingDrinking;
  @override
  String? get guestsPolicy;
  @override
  String? get workStyle;
  @override
  String? get gender;
  @override
  String? get genderPreference;
  @override
  Map<String, dynamic> get preferences;

  /// Create a copy of FlatmatesProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FlatmatesProfileModelImplCopyWith<_$FlatmatesProfileModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BootstrapData {
  FlatmatesProfileModel get profile => throw _privateConstructorUsedError;
  List<CatalogEntryModel> get catalogs => throw _privateConstructorUsedError;
  int get activeListingCount => throw _privateConstructorUsedError;
  int get conversationCount => throw _privateConstructorUsedError;
  int get unreadMessageCount => throw _privateConstructorUsedError;

  /// Create a copy of BootstrapData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BootstrapDataCopyWith<BootstrapData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BootstrapDataCopyWith<$Res> {
  factory $BootstrapDataCopyWith(
    BootstrapData value,
    $Res Function(BootstrapData) then,
  ) = _$BootstrapDataCopyWithImpl<$Res, BootstrapData>;
  @useResult
  $Res call({
    FlatmatesProfileModel profile,
    List<CatalogEntryModel> catalogs,
    int activeListingCount,
    int conversationCount,
    int unreadMessageCount,
  });

  $FlatmatesProfileModelCopyWith<$Res> get profile;
}

/// @nodoc
class _$BootstrapDataCopyWithImpl<$Res, $Val extends BootstrapData>
    implements $BootstrapDataCopyWith<$Res> {
  _$BootstrapDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BootstrapData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? profile = null,
    Object? catalogs = null,
    Object? activeListingCount = null,
    Object? conversationCount = null,
    Object? unreadMessageCount = null,
  }) {
    return _then(
      _value.copyWith(
            profile: null == profile
                ? _value.profile
                : profile // ignore: cast_nullable_to_non_nullable
                      as FlatmatesProfileModel,
            catalogs: null == catalogs
                ? _value.catalogs
                : catalogs // ignore: cast_nullable_to_non_nullable
                      as List<CatalogEntryModel>,
            activeListingCount: null == activeListingCount
                ? _value.activeListingCount
                : activeListingCount // ignore: cast_nullable_to_non_nullable
                      as int,
            conversationCount: null == conversationCount
                ? _value.conversationCount
                : conversationCount // ignore: cast_nullable_to_non_nullable
                      as int,
            unreadMessageCount: null == unreadMessageCount
                ? _value.unreadMessageCount
                : unreadMessageCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }

  /// Create a copy of BootstrapData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FlatmatesProfileModelCopyWith<$Res> get profile {
    return $FlatmatesProfileModelCopyWith<$Res>(_value.profile, (value) {
      return _then(_value.copyWith(profile: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BootstrapDataImplCopyWith<$Res>
    implements $BootstrapDataCopyWith<$Res> {
  factory _$$BootstrapDataImplCopyWith(
    _$BootstrapDataImpl value,
    $Res Function(_$BootstrapDataImpl) then,
  ) = __$$BootstrapDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    FlatmatesProfileModel profile,
    List<CatalogEntryModel> catalogs,
    int activeListingCount,
    int conversationCount,
    int unreadMessageCount,
  });

  @override
  $FlatmatesProfileModelCopyWith<$Res> get profile;
}

/// @nodoc
class __$$BootstrapDataImplCopyWithImpl<$Res>
    extends _$BootstrapDataCopyWithImpl<$Res, _$BootstrapDataImpl>
    implements _$$BootstrapDataImplCopyWith<$Res> {
  __$$BootstrapDataImplCopyWithImpl(
    _$BootstrapDataImpl _value,
    $Res Function(_$BootstrapDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BootstrapData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? profile = null,
    Object? catalogs = null,
    Object? activeListingCount = null,
    Object? conversationCount = null,
    Object? unreadMessageCount = null,
  }) {
    return _then(
      _$BootstrapDataImpl(
        profile: null == profile
            ? _value.profile
            : profile // ignore: cast_nullable_to_non_nullable
                  as FlatmatesProfileModel,
        catalogs: null == catalogs
            ? _value._catalogs
            : catalogs // ignore: cast_nullable_to_non_nullable
                  as List<CatalogEntryModel>,
        activeListingCount: null == activeListingCount
            ? _value.activeListingCount
            : activeListingCount // ignore: cast_nullable_to_non_nullable
                  as int,
        conversationCount: null == conversationCount
            ? _value.conversationCount
            : conversationCount // ignore: cast_nullable_to_non_nullable
                  as int,
        unreadMessageCount: null == unreadMessageCount
            ? _value.unreadMessageCount
            : unreadMessageCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$BootstrapDataImpl extends _BootstrapData {
  const _$BootstrapDataImpl({
    required this.profile,
    final List<CatalogEntryModel> catalogs = const [],
    this.activeListingCount = 0,
    this.conversationCount = 0,
    this.unreadMessageCount = 0,
  }) : _catalogs = catalogs,
       super._();

  @override
  final FlatmatesProfileModel profile;
  final List<CatalogEntryModel> _catalogs;
  @override
  @JsonKey()
  List<CatalogEntryModel> get catalogs {
    if (_catalogs is EqualUnmodifiableListView) return _catalogs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_catalogs);
  }

  @override
  @JsonKey()
  final int activeListingCount;
  @override
  @JsonKey()
  final int conversationCount;
  @override
  @JsonKey()
  final int unreadMessageCount;

  @override
  String toString() {
    return 'BootstrapData(profile: $profile, catalogs: $catalogs, activeListingCount: $activeListingCount, conversationCount: $conversationCount, unreadMessageCount: $unreadMessageCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BootstrapDataImpl &&
            (identical(other.profile, profile) || other.profile == profile) &&
            const DeepCollectionEquality().equals(other._catalogs, _catalogs) &&
            (identical(other.activeListingCount, activeListingCount) ||
                other.activeListingCount == activeListingCount) &&
            (identical(other.conversationCount, conversationCount) ||
                other.conversationCount == conversationCount) &&
            (identical(other.unreadMessageCount, unreadMessageCount) ||
                other.unreadMessageCount == unreadMessageCount));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    profile,
    const DeepCollectionEquality().hash(_catalogs),
    activeListingCount,
    conversationCount,
    unreadMessageCount,
  );

  /// Create a copy of BootstrapData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BootstrapDataImplCopyWith<_$BootstrapDataImpl> get copyWith =>
      __$$BootstrapDataImplCopyWithImpl<_$BootstrapDataImpl>(this, _$identity);
}

abstract class _BootstrapData extends BootstrapData {
  const factory _BootstrapData({
    required final FlatmatesProfileModel profile,
    final List<CatalogEntryModel> catalogs,
    final int activeListingCount,
    final int conversationCount,
    final int unreadMessageCount,
  }) = _$BootstrapDataImpl;
  const _BootstrapData._() : super._();

  @override
  FlatmatesProfileModel get profile;
  @override
  List<CatalogEntryModel> get catalogs;
  @override
  int get activeListingCount;
  @override
  int get conversationCount;
  @override
  int get unreadMessageCount;

  /// Create a copy of BootstrapData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BootstrapDataImplCopyWith<_$BootstrapDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
