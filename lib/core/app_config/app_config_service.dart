import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../analytics/analytics_service.dart';
import '../config/endpoints.dart';
import '../providers.dart';

enum AppUpdateStatus { upToDate, optionalUpdate, forceUpdate }

/// Result from the backend's POST /versions/check endpoint.
class VersionCheckResult {
  const VersionCheckResult({
    required this.updateAvailable,
    required this.isMandatory,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.minSupportedVersion,
  });

  final bool updateAvailable;
  final bool isMandatory;
  final String? latestVersion;
  final String? downloadUrl;
  final String? releaseNotes;
  final String? minSupportedVersion;

  factory VersionCheckResult.fromJson(Map<String, dynamic> json) {
    return VersionCheckResult(
      updateAvailable: json['update_available'] as bool? ?? false,
      isMandatory: json['is_mandatory'] as bool? ?? false,
      latestVersion: json['latest_version'] as String?,
      downloadUrl: json['download_url'] as String?,
      releaseNotes: json['release_notes'] as String?,
      minSupportedVersion: json['min_supported_version'] as String?,
    );
  }
}

class AppConfigService {
  AppConfigService({required this.ref});

  final Ref ref;
  static const _dismissedVersionKey = 'optional_update_dismissed_version';

  /// Calls the backend's POST /versions/check endpoint to see if an update
  /// is available for the current app/platform/version.
  Future<VersionCheckResult?> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final response = await ref.read(apiClientProvider).post(
        FlatmatesEndpoints.versionCheck,
        data: {
          'app': 'flatmates',
          'platform': defaultTargetPlatform.name,
          'current_version': packageInfo.version,
          'build_number': int.tryParse(packageInfo.buildNumber),
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return VersionCheckResult.fromJson(data);
      }
      return null;
    } catch (e, st) {
      try {
        unawaited(ref.read(analyticsServiceProvider).recordError(e, st));
      } catch (e2) {
        debugPrint('AppConfigService.checkForUpdates: $e2');
      }
      return null;
    }
  }

  /// Maps the backend's version check result to a local update status,
  /// respecting per-version optional-update dismissal.
  Future<AppUpdateStatus> resolveUpdateStatus(
    VersionCheckResult result,
  ) async {
    if (!result.updateAvailable) return AppUpdateStatus.upToDate;
    if (result.isMandatory) return AppUpdateStatus.forceUpdate;

    // Optional update — check if user already dismissed this version.
    if (result.latestVersion != null) {
      final prefs = ref.read(appPreferencesProvider);
      final dismissed = prefs.getString(_dismissedVersionKey);
      if (dismissed == result.latestVersion) {
        return AppUpdateStatus.upToDate;
      }
    }

    return AppUpdateStatus.optionalUpdate;
  }

  Future<void> dismissOptionalUpdate(String version) async {
    final prefs = ref.read(appPreferencesProvider);
    await prefs.setString(_dismissedVersionKey, version);
  }
}

final appConfigServiceProvider = Provider<AppConfigService>(
  (ref) => AppConfigService(ref: ref),
);
