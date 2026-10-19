import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';

/// Remote notification preferences from `GET/PUT /users/notification-settings`.
///
/// The contract has four keys and no others: `push_notifications`,
/// `email_notifications`, `sms_notifications` and `promotional_emails`. A PUT
/// with any other key is a 422, so [toJson] writes these four only.
class RemoteNotificationSettings {
  const RemoteNotificationSettings({
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.smsNotifications = false,
    this.promotionalEmails = false,
  });

  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;
  final bool promotionalEmails;

  factory RemoteNotificationSettings.fromJson(Map<String, dynamic> json) {
    return RemoteNotificationSettings(
      emailNotifications: json['email_notifications'] as bool? ?? true,
      pushNotifications: json['push_notifications'] as bool? ?? true,
      smsNotifications: json['sms_notifications'] as bool? ?? false,
      promotionalEmails: json['promotional_emails'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'email_notifications': emailNotifications,
    'push_notifications': pushNotifications,
    'sms_notifications': smsNotifications,
    'promotional_emails': promotionalEmails,
  };
}

/// Remote privacy preferences from `GET/PUT /users/privacy-settings`.
///
/// `PUT` is a partial update (`PrivacySettingsPatch`): send only the keys that
/// changed, never null.
class RemotePrivacySettings {
  const RemotePrivacySettings({
    this.profileVisibility = 'public',
    this.locationSharing = true,
    this.contactSharing = true,
    this.searchHistoryTracking = true,
    this.hideLastName = false,
  });

  final String profileVisibility;
  final bool locationSharing;
  final bool contactSharing;
  final bool searchHistoryTracking;
  final bool hideLastName;

  factory RemotePrivacySettings.fromJson(Map<String, dynamic> json) {
    return RemotePrivacySettings(
      profileVisibility: json['profile_visibility'] as String? ?? 'public',
      locationSharing: json['location_sharing'] as bool? ?? true,
      contactSharing: json['contact_sharing'] as bool? ?? true,
      searchHistoryTracking: json['search_history_tracking'] as bool? ?? true,
      hideLastName: json['hide_last_name'] as bool? ?? false,
    );
  }
}

class SettingsRepository {
  const SettingsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<RemoteNotificationSettings> fetchNotificationSettings() async {
    final response = await _apiClient.get(
      FlatmatesEndpoints.notificationSettings,
    );
    final data = Map<String, dynamic>.from(
      response.data is Map ? response.data as Map : const {},
    );
    return RemoteNotificationSettings.fromJson(data);
  }

  /// `PUT /users/notification-settings`: the four contract keys only.
  Future<void> updateNotificationSettings(
    RemoteNotificationSettings settings,
  ) async {
    await _apiClient.put(
      FlatmatesEndpoints.notificationSettings,
      data: settings.toJson(),
    );
  }

  Future<RemotePrivacySettings> fetchPrivacySettings() async {
    final response = await _apiClient.get(FlatmatesEndpoints.privacySettings);
    final data = Map<String, dynamic>.from(
      response.data is Map ? response.data as Map : const {},
    );
    return RemotePrivacySettings.fromJson(data);
  }

  /// `PUT /users/privacy-settings` with only the keys in [patch].
  Future<void> updatePrivacySettings(Map<String, bool> patch) async {
    await _apiClient.put(FlatmatesEndpoints.privacySettings, data: patch);
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(apiClient: ref.watch(apiClientProvider)),
);
