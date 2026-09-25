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
  SecureSessionStorage({
    required this.persistSessionKey,
    @visibleForTesting FlutterSecureStorage? secure,
  }) : _secure = secure ?? _defaultSecure;

  /// Same key supabase_flutter uses: `sb-<project-ref>-auth-token`.
  static String keyForUrl(String supabaseUrl) =>
      'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';

  final String persistSessionKey;

  static const _installMarkerKey = 'secure_session_install_marker';

  // first_unlock: the token stays readable for background refresh.
  // Android options stay at the default so this shares one store format with
  // SecureKvStore (mixing encryptedSharedPreferences modes breaks deletes).
  static const _defaultSecure = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  final FlutterSecureStorage _secure;

  LocalStorage? _fallback;

  @override
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(persistSessionKey);
      if (legacy != null) {
        // A plaintext session is always the newest one: the old default
        // storage kept writing it until this build. Overwrite, then drop it.
        await _secure.write(key: persistSessionKey, value: legacy);
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

  // Every keychain call is guarded: an error (for example iOS error -25308
  // on a background launch before first unlock) must never crash
  // Supabase.initialize and block runApp. A failed read means "no session".

  @override
  Future<bool> hasAccessToken() async {
    final fallback = _fallback;
    if (fallback != null) return fallback.hasAccessToken();
    try {
      return await _secure.containsKey(key: persistSessionKey);
    } catch (e) {
      debugPrint('SecureSessionStorage.hasAccessToken: $e');
      return false;
    }
  }

  @override
  Future<String?> accessToken() async {
    final fallback = _fallback;
    if (fallback != null) return fallback.accessToken();
    try {
      return await _secure.read(key: persistSessionKey);
    } catch (e) {
      debugPrint('SecureSessionStorage.accessToken: $e');
      return null;
    }
  }

  @override
  Future<void> removePersistedSession() async {
    final fallback = _fallback;
    if (fallback != null) return fallback.removePersistedSession();
    try {
      await _secure.delete(key: persistSessionKey);
    } catch (e) {
      debugPrint('SecureSessionStorage.removePersistedSession: $e');
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    final fallback = _fallback;
    if (fallback != null) return fallback.persistSession(persistSessionString);
    try {
      await _secure.write(key: persistSessionKey, value: persistSessionString);
    } catch (e) {
      debugPrint('SecureSessionStorage.persistSession: $e');
    }
  }
}
