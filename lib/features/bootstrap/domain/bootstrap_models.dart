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

/// Server-owned Supabase Realtime subscription config from bootstrap.
///
/// Backend shape: `{ provider, channel, private, events }`.
class FlatmatesRealtimeConfig {
  const FlatmatesRealtimeConfig({
    this.provider = 'supabase',
    required this.channel,
    this.privateChannel = true,
    this.events = const [],
  });

  final String provider;
  final String channel;
  final bool privateChannel;
  final List<String> events;

  factory FlatmatesRealtimeConfig.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['events'];
    final events = rawEvents is List
        ? rawEvents
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList(growable: false)
        : const <String>[];
    return FlatmatesRealtimeConfig(
      provider: json['provider'] as String? ?? 'supabase',
      channel: json['channel'] as String? ?? '',
      privateChannel: json['private'] as bool? ?? true,
      events: events,
    );
  }

  /// Client fallback when bootstrap omits `realtime` (older backends).
  factory FlatmatesRealtimeConfig.fallbackForUser(int userId) {
    return FlatmatesRealtimeConfig(
      channel: 'flatmates:user:$userId',
      events: const [
        'new_match',
        'new_message',
        'conversation_updated',
        'visit_updated',
        'listing_status_changed',
        'new_notification',
      ],
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FlatmatesRealtimeConfig &&
            other.provider == provider &&
            other.channel == channel &&
            other.privateChannel == privateChannel &&
            _listEquals(other.events, events);
  }

  @override
  int get hashCode =>
      Object.hash(provider, channel, privateChannel, Object.hashAll(events));
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
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
    FlatmatesRealtimeConfig? realtime,
  }) = _BootstrapData;

  factory BootstrapData.fromJson(Map<String, dynamic> json) {
    final realtimeJson = json['realtime'];
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
      realtime: realtimeJson is Map
          ? FlatmatesRealtimeConfig.fromJson(
              Map<String, dynamic>.from(realtimeJson),
            )
          : null,
    );
  }
}
