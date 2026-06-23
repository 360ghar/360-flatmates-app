import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment { dev, staging, prod }

bool? _parseBool(String? raw) {
  if (raw == null) return null;
  final value = raw.trim().toLowerCase();
  if (value.isEmpty) return null;
  if (value == 'true' || value == '1' || value == 'yes') return true;
  if (value == 'false' || value == '0' || value == 'no') return false;
  return null;
}

final class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.enableDebugLogs,
    this.googleWebClientId = '',
    this.googleIosClientId = '',
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabasePublishableKey;
  final bool enableDebugLogs;

  /// Google **Web** OAuth client id, used as the Android `serverClientId` and
  /// as the audience Supabase validates native ID tokens against. Empty until
  /// the Phase 0 Google Cloud Console setup is complete.
  final String googleWebClientId;

  /// Google **iOS** OAuth client id, used as the iOS `clientId`. Empty until
  /// the Phase 0 setup is complete.
  final String googleIosClientId;

  /// Whether native Google sign-in can be attempted (web client id present).
  bool get isGoogleSignInConfigured => googleWebClientId.trim().isNotEmpty;

  static AppEnvironment _parseEnvironment(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      case 'stage':
      case 'staging':
        return AppEnvironment.staging;
      default:
        return AppEnvironment.dev;
    }
  }

  factory AppConfig.fromEnvironment() {
    const envDefine = String.fromEnvironment('APP_ENV');
    final environment = _parseEnvironment(
      envDefine.trim().isNotEmpty
          ? envDefine
          : (dotenv.env['APP_ENV'] ?? 'dev'),
    );

    const apiDefine = String.fromEnvironment('API_BASE_URL');
    final apiBaseUrl = apiDefine.trim().isNotEmpty
        ? apiDefine
        : (dotenv.env['API_BASE_URL'] ?? '');

    const supabaseUrlDefine = String.fromEnvironment('SUPABASE_URL');
    final supabaseUrl = supabaseUrlDefine.trim().isNotEmpty
        ? supabaseUrlDefine
        : (dotenv.env['SUPABASE_URL'] ?? '');

    const supabaseKeyDefine = String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    );
    final supabasePublishableKey = supabaseKeyDefine.trim().isNotEmpty
        ? supabaseKeyDefine
        : (dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '');

    const debugLogsDefine = String.fromEnvironment('ENABLE_DEBUG_LOGS');
    final enableDebugLogs =
        _parseBool(
          debugLogsDefine.trim().isNotEmpty
              ? debugLogsDefine
              : dotenv.env['ENABLE_DEBUG_LOGS'],
        ) ??
        !kReleaseMode;

    const googleWebClientIdDefine = String.fromEnvironment(
      'GOOGLE_WEB_CLIENT_ID',
    );
    final googleWebClientId = googleWebClientIdDefine.trim().isNotEmpty
        ? googleWebClientIdDefine
        : (dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '');

    const googleIosClientIdDefine = String.fromEnvironment(
      'GOOGLE_IOS_CLIENT_ID',
    );
    final googleIosClientId = googleIosClientIdDefine.trim().isNotEmpty
        ? googleIosClientIdDefine
        : (dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '');

    if (apiBaseUrl.trim().isEmpty) {
      throw StateError(
        'API_BASE_URL is required. Set it via .env, --dart-define, or environment variable.',
      );
    }
    if (supabaseUrl.trim().isEmpty || supabasePublishableKey.trim().isEmpty) {
      throw StateError(
        'Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY configuration.',
      );
    }

    return AppConfig(
      environment: environment,
      apiBaseUrl: apiBaseUrl,
      supabaseUrl: supabaseUrl,
      supabasePublishableKey: supabasePublishableKey,
      enableDebugLogs: enableDebugLogs,
      googleWebClientId: googleWebClientId,
      googleIosClientId: googleIosClientId,
    );
  }
}
