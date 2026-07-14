import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';

/// Remote notification preferences from `GET/PUT /users/notification-settings`.
///
/// Backend schema: push_notifications, visit_reminders, property_updates,
/// promotional_emails, plus a free-form [categories] map (`extra=allow`).
class RemoteNotificationSettings {
  const RemoteNotificationSettings({
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.smsNotifications = false,
    this.visitReminders = true,
    this.propertyUpdates = true,
    this.promotionalEmails = false,
    this.onboarding = true,
    this.digest = true,
    this.categories = const {},
    this.raw = const {},
  });

  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;
  final bool visitReminders;
  final bool propertyUpdates;
  final bool promotionalEmails;
  final bool onboarding;
  final bool digest;
  final Map<String, bool> categories;

  /// Full JSON as returned by the API so PUTs can preserve unknown fields.
  final Map<String, dynamic> raw;

  factory RemoteNotificationSettings.fromJson(Map<String, dynamic> json) {
    final categoriesRaw = json['categories'];
    final categories = <String, bool>{};
    if (categoriesRaw is Map) {
      for (final entry in categoriesRaw.entries) {
        categories[entry.key.toString()] = entry.value == true;
      }
    }
    return RemoteNotificationSettings(
      emailNotifications: json['email_notifications'] as bool? ?? true,
      pushNotifications: json['push_notifications'] as bool? ?? true,
      smsNotifications: json['sms_notifications'] as bool? ?? false,
      visitReminders: json['visit_reminders'] as bool? ?? true,
      propertyUpdates: json['property_updates'] as bool? ?? true,
      promotionalEmails: json['promotional_emails'] as bool? ?? false,
      onboarding: json['onboarding'] as bool? ?? true,
      digest: json['digest'] as bool? ?? true,
      categories: categories,
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() {
    final payload = Map<String, dynamic>.from(raw);
    payload.addAll({
      'email_notifications': emailNotifications,
      'push_notifications': pushNotifications,
      'sms_notifications': smsNotifications,
      'visit_reminders': visitReminders,
      'property_updates': propertyUpdates,
      'promotional_emails': promotionalEmails,
      'onboarding': onboarding,
      'digest': digest,
      'categories': categories,
    });
    return payload;
  }
}

/// Remote privacy preferences from `GET/PUT /users/privacy-settings`.
class RemotePrivacySettings {
  const RemotePrivacySettings({
    this.profileVisibility = 'public',
    this.locationSharing = true,
    this.contactSharing = true,
    this.searchHistoryTracking = true,
    this.raw = const {},
  });

  final String profileVisibility;
  final bool locationSharing;
  final bool contactSharing;
  final bool searchHistoryTracking;

  /// Full JSON as returned by the API so PUTs can preserve unknown fields.
  final Map<String, dynamic> raw;

  factory RemotePrivacySettings.fromJson(Map<String, dynamic> json) {
    return RemotePrivacySettings(
      profileVisibility: json['profile_visibility'] as String? ?? 'public',
      locationSharing: json['location_sharing'] as bool? ?? true,
      contactSharing: json['contact_sharing'] as bool? ?? true,
      searchHistoryTracking: json['search_history_tracking'] as bool? ?? true,
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() {
    final payload = Map<String, dynamic>.from(raw);
    payload.addAll({
      'profile_visibility': profileVisibility,
      'location_sharing': locationSharing,
      'contact_sharing': contactSharing,
      'search_history_tracking': searchHistoryTracking,
    });
    return payload;
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

  Future<void> updateNotificationSettings(Map<String, dynamic> payload) async {
    await _apiClient.put(
      FlatmatesEndpoints.notificationSettings,
      data: payload,
    );
  }

  Future<RemotePrivacySettings> fetchPrivacySettings() async {
    final response = await _apiClient.get(FlatmatesEndpoints.privacySettings);
    final data = Map<String, dynamic>.from(
      response.data is Map ? response.data as Map : const {},
    );
    return RemotePrivacySettings.fromJson(data);
  }

  Future<void> updatePrivacySettings(Map<String, dynamic> payload) async {
    await _apiClient.put(FlatmatesEndpoints.privacySettings, data: payload);
  }

  /// Compat endpoint that accepts an arbitrary dict (e.g. `hide_last_name`).
  Future<void> updatePrivacySettingsCompat(Map<String, dynamic> payload) async {
    await _apiClient.put(
      FlatmatesEndpoints.privacySettingsCompat,
      data: payload,
    );
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(apiClient: ref.watch(apiClientProvider)),
);
