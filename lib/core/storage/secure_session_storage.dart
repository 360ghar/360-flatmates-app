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

  late SharedPreferences _prefs;
  bool _useFallback = false;
  bool _signedOut = false;
  Future<void> _pending = Future<void>.value();

  String get _signedOutKey => '$persistSessionKey-signed-out';

  // Supabase emits storage writes without awaiting the previous event. Keep
  // token refresh, sign-out, and the next login in their original order.
  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>(
      (_) {},
      onError: (Object error) {
        debugPrint('SecureSessionStorage.operation: $error');
      },
    );
    return result;
  }

  @override
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _signedOut = _prefs.getBool(_signedOutKey) ?? false;
    try {
      final legacy = _prefs.getString(persistSessionKey);
      if (_signedOut) {
        // A failed keychain delete must not restore an account on restart,
        // including through the legacy migration or plaintext fallback.
        await _deleteStoredSession();
      } else if (legacy != null) {
        // A plaintext session is always the newest one: the old default
        // storage kept writing it until this build. Overwrite, then drop it.
        await _secure.write(key: persistSessionKey, value: legacy);
        await _prefs.remove(persistSessionKey);
      } else if (!_prefs.containsKey(_installMarkerKey)) {
        // SharedPreferences is wiped on uninstall but the iOS keychain is
        // not. No marker and no legacy session = fresh install, so drop any
        // session left behind by a previous install.
        await _secure.delete(key: persistSessionKey);
      }
      await _prefs.setBool(_installMarkerKey, true);
    } catch (e) {
      debugPrint('SecureSessionStorage: secure storage unavailable: $e');
      _useFallback = true;
    }
  }

  // Every keychain call is guarded: an error (for example iOS error -25308
  // on a background launch before first unlock) must never crash
  // Supabase.initialize and block runApp. A failed read means "no session".

  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;

  @override
  Future<String?> accessToken() => _serialize(() async {
    if (_signedOut) return null;
    if (_useFallback) return _prefs.getString(persistSessionKey);
    try {
      return await _secure.read(key: persistSessionKey);
    } catch (e) {
      debugPrint('SecureSessionStorage.accessToken: $e');
      return null;
    }
  });

  @override
  Future<void> removePersistedSession() => _serialize(() async {
    _signedOut = true;
    try {
      if (!await _prefs.setBool(_signedOutKey, true)) {
        throw StateError('Could not persist session invalidation');
      }
    } finally {
      await _deleteStoredSession();
    }
  });

  Future<void> _deleteStoredSession() async {
    try {
      await _prefs.remove(persistSessionKey);
    } catch (e) {
      debugPrint('SecureSessionStorage.removePlaintextSession: $e');
    }
    try {
      await _secure.delete(key: persistSessionKey);
    } catch (e) {
      debugPrint('SecureSessionStorage.removePersistedSession: $e');
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) =>
      _serialize(() async {
        try {
          if (_useFallback) {
            if (!await _prefs.setString(
              persistSessionKey,
              persistSessionString,
            )) {
              throw StateError('Could not persist session');
            }
          } else {
            await _secure.write(
              key: persistSessionKey,
              value: persistSessionString,
            );
          }
          if (!await _prefs.remove(_signedOutKey)) {
            throw StateError('Could not clear session invalidation');
          }
          _signedOut = false;
        } catch (e) {
          debugPrint('SecureSessionStorage.persistSession: $e');
        }
      });
}
