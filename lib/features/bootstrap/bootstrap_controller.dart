import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class CatalogEntryModel {
  const CatalogEntryModel({
    required this.key,
    required this.version,
    required this.payload,
  });

  final String key;
  final int version;
  final Map<String, dynamic> payload;

  factory CatalogEntryModel.fromJson(Map<String, dynamic> json) {
    return CatalogEntryModel(
      key: json['key'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 0,
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
    );
  }
}

class FlatmatesProfileModel {
  const FlatmatesProfileModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.profileImageUrl,
    required this.mode,
    required this.profileStatus,
    required this.onboardingCompleted,
    required this.bio,
    required this.age,
    required this.profession,
    required this.budgetMin,
    required this.budgetMax,
    required this.moveInTimeline,
    required this.city,
    required this.state,
    required this.locality,
    required this.sleepSchedule,
    required this.cleanliness,
    required this.foodHabits,
    required this.smokingDrinking,
    required this.guestsPolicy,
    required this.workStyle,
    required this.gender,
    required this.genderPreference,
    required this.preferences,
  });

  final int id;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? profileImageUrl;
  final String? mode;
  final String profileStatus;
  final bool onboardingCompleted;
  final String? bio;
  final int? age;
  final String? profession;
  final double? budgetMin;
  final double? budgetMax;
  final String? moveInTimeline;
  final String? city;
  final String? state;
  final String? locality;
  final String? sleepSchedule;
  final String? cleanliness;
  final String? foodHabits;
  final String? smokingDrinking;
  final String? guestsPolicy;
  final String? workStyle;
  final String? gender;
  final String? genderPreference;
  final Map<String, dynamic> preferences;

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
      profession: json['profession'] as String? ?? preferences['profession'] as String?,
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

class BootstrapData {
  const BootstrapData({
    required this.profile,
    required this.catalogs,
    required this.activeListingCount,
    required this.conversationCount,
    required this.unreadMessageCount,
  });

  final FlatmatesProfileModel profile;
  final List<CatalogEntryModel> catalogs;
  final int activeListingCount;
  final int conversationCount;
  final int unreadMessageCount;

  factory BootstrapData.fromJson(Map<String, dynamic> json) {
    return BootstrapData(
      profile: FlatmatesProfileModel.fromJson(
        Map<String, dynamic>.from(json['profile'] as Map? ?? const {}),
      ),
      catalogs: ((json['catalogs'] as List?) ?? const [])
          .map(
            (item) => CatalogEntryModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      activeListingCount: (json['active_listing_count'] as num?)?.toInt() ?? 0,
      conversationCount: (json['conversation_count'] as num?)?.toInt() ?? 0,
      unreadMessageCount: (json['unread_message_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class BootstrapController extends StateNotifier<AsyncValue<BootstrapData?>> {
  BootstrapController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _ref
          .watch(apiClientProvider)
          .get('/flatmates/bootstrap');
      return BootstrapData.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    });
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

final bootstrapControllerProvider =
    StateNotifierProvider<BootstrapController, AsyncValue<BootstrapData?>>(
      (ref) => BootstrapController(ref),
    );
