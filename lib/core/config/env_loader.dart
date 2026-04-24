import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final class EnvLoader {
  const EnvLoader._();

  /// Loads environment variables from a `.env` file.
  ///
  /// Unlike listing `.env` as a Flutter asset (which crashes the build when
  /// the file is absent), this method loads the file from the file system at
  /// runtime and gracefully handles the missing-file case.
  ///
  /// Returns `true` when the file was loaded successfully, `false` when the
  /// file was missing or could not be parsed. In either case `dotenv.env` is
  /// safe to read (it will simply be empty on failure), and callers should
  /// fall back to `--dart-define` values or `String.fromEnvironment`.
  static Future<bool> load({String fileName = '.env'}) async {
    try {
      final file = File(fileName);
      if (!await file.exists()) {
        debugPrint('[EnvLoader] $fileName not found – falling back to '
            '--dart-define / environment variables.');
        return false;
      }
      await dotenv.load(fileName: fileName);
      return true;
    } on FileSystemException catch (e) {
      debugPrint('[EnvLoader] FileSystemException reading $fileName: $e');
      return false;
    } catch (e) {
      debugPrint('[EnvLoader] Error loading $fileName: $e');
      return false;
    }
  }
}
