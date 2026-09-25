import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the Supabase session (access and refresh token) in the platform
/// keychain / keystore instead of plaintext SharedPreferences, which is the
/// supabase_flutter default.
///
/// On first run it moves an existing session out of SharedPreferences, so
/// signed-in users stay signed in. If secure storage is unavailable, it falls
/// back to the SharedPreferences storage rather than signing the user out.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({required this.persistSessionKey});

  /// Same key supabase_flutter uses: `sb-<project-ref>-auth-token`.
  static String keyForUrl(String supabaseUrl) =>
      'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';

  final String persistSessionKey;

  static const _installMarkerKey = 'secure_session_install_marker';

  // first_unlock: the token stays readable for background refresh.
  static const _secure = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  LocalStorage? _fallback;

  @override
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(persistSessionKey);
      if (legacy != null) {
        if (!await _secure.containsKey(key: persistSessionKey)) {
          await _secure.write(key: persistSessionKey, value: legacy);
        }
        await prefs.remove(persistSessionKey);
      } else if (!prefs.containsKey(_installMarkerKey)) {
        // SharedPreferences is wiped on uninstall but the iOS keychain is
        // not. No marker and no legacy session = fresh install, so drop any
        // session left behind by a previous install.
        await _secure.delete(key: persistSessionKey);
      }
      await prefs.setBool(_installMarkerKey, true);
    } catch (e) {
      debugPrint('SecureSessionStorage: secure storage unavailable: $e');
      final fallback = SharedPreferencesLocalStorage(
        persistSessionKey: persistSessionKey,
      );
      await fallback.initialize();
      _fallback = fallback;
    }
  }

  @override
  Future<bool> hasAccessToken() =>
      _fallback?.hasAccessToken() ??
      _secure.containsKey(key: persistSessionKey);

  @override
  Future<String?> accessToken() =>
      _fallback?.accessToken() ?? _secure.read(key: persistSessionKey);

  @override
  Future<void> removePersistedSession() =>
      _fallback?.removePersistedSession() ??
      _secure.delete(key: persistSessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _fallback?.persistSession(persistSessionString) ??
      _secure.write(key: persistSessionKey, value: persistSessionString);
}
