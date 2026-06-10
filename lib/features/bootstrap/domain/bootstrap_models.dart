import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/safe_json_list.dart';

part 'bootstrap_models.freezed.dart';

@Freezed()
class CatalogEntryModel with _$CatalogEntryModel {
  const CatalogEntryModel._();

  const factory CatalogEntryModel({
    required String key,
    @Default(0) int version,
    @Default({}) Map<String, dynamic> payload,
  }) = _CatalogEntryModel;

  factory CatalogEntryModel.fromJson(Map<String, dynamic> json) {
    return CatalogEntryModel(
      key: json['key'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 0,
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
    );
  }
}

@Freezed()
class FlatmatesProfileModel with _$FlatmatesProfileModel {
  const FlatmatesProfileModel._();

  const factory FlatmatesProfileModel({
    required int id,
    String? fullName,
    String? phone,
    String? email,
    String? profileImageUrl,
    String? mode,
    @Default('draft') String profileStatus,
    @Default(false) bool onboardingCompleted,
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
    @Default({}) Map<String, dynamic> preferences,
  }) = _FlatmatesProfileModel;

  factory FlatmatesProfileModel.fromJson(Map<String, dynamic> json) {
    final preferences = Map<String, dynamic>.from(
      json['preferences'] as Map? ?? const {},
    );
    return FlatmatesProfileModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      mode: json['mode'] as String?,
      profileStatus: json['profile_status'] as String? ?? 'draft',
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      bio: json['bio'] as String?,
      age: (json['age'] as num?)?.toInt(),
      profession:
          json['profession'] as String? ?? preferences['profession'] as String?,
      budgetMin: (json['budget_min'] as num?)?.toDouble(),
      budgetMax: (json['budget_max'] as num?)?.toDouble(),
      moveInTimeline: json['move_in_timeline'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      locality: json['locality'] as String?,
      sleepSchedule: json['sleep_schedule'] as String?,
      cleanliness: json['cleanliness'] as String?,
      foodHabits: json['food_habits'] as String?,
      smokingDrinking: json['smoking_drinking'] as String?,
      guestsPolicy: json['guests_policy'] as String?,
      workStyle: json['work_style'] as String?,
      gender: json['gender'] as String?,
      genderPreference: json['gender_preference'] as String?,
      preferences: preferences,
    );
  }
}

@Freezed()
class BootstrapData with _$BootstrapData {
  const BootstrapData._();

  const factory BootstrapData({
    required FlatmatesProfileModel profile,
    @Default([]) List<CatalogEntryModel> catalogs,
    @Default(0) int activeListingCount,
    @Default(0) int conversationCount,
    @Default(0) int unreadMessageCount,
  }) = _BootstrapData;

  factory BootstrapData.fromJson(Map<String, dynamic> json) {
    return BootstrapData(
      profile: FlatmatesProfileModel.fromJson(
        Map<String, dynamic>.from(json['profile'] as Map? ?? const {}),
      ),
      catalogs: safeJsonList(
        json['catalogs'] as List?,
        CatalogEntryModel.fromJson,
        label: 'catalogs',
      ),
      activeListingCount: (json['active_listing_count'] as num?)?.toInt() ?? 0,
      conversationCount: (json['conversation_count'] as num?)?.toInt() ?? 0,
      unreadMessageCount: (json['unread_message_count'] as num?)?.toInt() ?? 0,
    );
  }
}
