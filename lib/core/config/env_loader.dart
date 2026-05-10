import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final class EnvLoader {
  const EnvLoader._();

  /// Loads environment variables from a `.env` file.
  ///
  /// Uses flutter_dotenv's asset-bundle loading with `isOptional: true` so
  /// that `dotenv.env` is always safe to read (empty on failure). Callers
  /// should fall back to `--dart-define` values or `String.fromEnvironment`.
  static Future<bool> load({String fileName = '.env'}) async {
    try {
      await dotenv.load(fileName: fileName, isOptional: true);
      if (dotenv.env.isNotEmpty) return true;
    } catch (_) {}

    debugPrint(
      '[EnvLoader] $fileName not found in asset bundle – falling back '
      'to --dart-define / environment variables.',
    );
    return false;
  }
}
