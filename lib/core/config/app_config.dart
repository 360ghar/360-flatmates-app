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
    required this.supabaseAnonKey,
    required this.enableDebugLogs,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool enableDebugLogs;

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
    var apiBaseUrl = apiDefine.trim().isNotEmpty
        ? apiDefine
        : (dotenv.env['API_BASE_URL'] ?? '');

    const supabaseUrlDefine = String.fromEnvironment('SUPABASE_URL');
    var supabaseUrl = supabaseUrlDefine.trim().isNotEmpty
        ? supabaseUrlDefine
        : (dotenv.env['SUPABASE_URL'] ?? '');

    const supabaseKeyDefine = String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    );
    var supabaseAnonKey = supabaseKeyDefine.trim().isNotEmpty
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

    if (apiBaseUrl.trim().isEmpty) {
      throw StateError(
        'API_BASE_URL is required. Set it via .env, --dart-define, or environment variable.',
      );
    }
    if (supabaseUrl.trim().isEmpty || supabaseAnonKey.trim().isEmpty) {
      throw StateError(
        'Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY configuration.',
      );
    }

    return AppConfig(
      environment: environment,
      apiBaseUrl: apiBaseUrl,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      enableDebugLogs: enableDebugLogs,
    );
  }
}
