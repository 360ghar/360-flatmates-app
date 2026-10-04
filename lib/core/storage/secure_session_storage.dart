import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the Supabase session (access and refresh token) in the platform
/// keychain / keystore instead of plaintext SharedPreferences, which is the
/// supabase_flutter default.
///
/// On first run it moves an existing session out of SharedPreferences, so
/// signed-in users stay signed in. When the keychain is unusable it keeps the
/// plaintext copy as the source of truth rather than signing the user out.
///
/// **One session, one store.** A `...-store` marker in SharedPreferences
/// records which store holds the live session and every read follows it, so a
/// stale copy in the other store can never overwrite a newer session. The
/// marker is written *after* the credentials it describes, and a session is
/// only recorded as `secure` once that marker is durable — a keychain-only
/// session with no marker is what the fresh-install wipe would delete.
///
/// Sign-out wins over every copy: the `...-signed-out` marker is written
/// before anything is deleted, and reads and migration honour it until a new
/// session is saved successfully.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({
    required this.persistSessionKey,
    @visibleForTesting FlutterSecureStorage? secure,
  }) : _secure = secure ?? _defaultSecure;

  /// Same key supabase_flutter uses: `sb-<project-ref>-auth-token`.
  static String keyForUrl(String supabaseUrl) =>
      'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';

  static const _storeSecure = 'secure';
  static const _storePrefs = 'prefs';

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
  bool _signedOut = false;

  /// Which store holds the live session, from the `...-store` marker. `null`
  /// when no marker was written yet (older build, or the write failed), in
  /// which case the keychain is read first and the plaintext copy second.
  String? _store;

  Future<void> _pending = Future<void>.value();

  String get _signedOutKey => '$persistSessionKey-signed-out';
  String get _storeKey => '$persistSessionKey-store';

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
    _store = _prefs.getString(_storeKey);
    final hadInstallMarker = _prefs.containsKey(_installMarkerKey);

    if (_signedOut) {
      // Sign-out wins: the session was invalidated, so no copy may come back —
      // not the plaintext one, not the keychain one.
      await _deleteStoredSession();
      _store = null;
      await _writeStoreMarker(null);
      await _writeInstallMarker();
      return;
    }

    if (_store == _storePrefs) {
      final plaintext = _prefs.getString(persistSessionKey);
      if (plaintext != null) {
        // The keychain may work again (a background launch before first
        // unlock makes it fail once): try to move the session back to it. The
        // plaintext copy is the source of truth here, so re-migrating it can
        // never overwrite a newer keychain token.
        await _migrateLegacySession(plaintext);
      } else {
        // The copy this marker names is gone: drop the marker so the keychain
        // is read again.
        _store = null;
        await _writeStoreMarker(null);
      }
      await _writeInstallMarker();
      return;
    }

    final legacy = _prefs.getString(persistSessionKey);
    if (legacy != null) {
      await _migrateLegacySession(legacy);
      await _writeInstallMarker();
      return;
    }

    if (_store == _storeSecure) {
      // The marker names the keychain, so this is not a fresh install even if
      // the install marker is missing: never wipe the session it points at.
      await _writeInstallMarker();
      return;
    }

    if (!hadInstallMarker) {
      // Fresh install: SharedPreferences is wiped on uninstall but the iOS
      // keychain is not, so a session left behind by a previous install must
      // go. Only once the install marker is durable — a failed marker write
      // would otherwise make every later launch look like a fresh install and
      // delete a session saved since.
      if (await _writeInstallMarker()) await _secureDelete();
      return;
    }

    await _writeInstallMarker();
  }

  /// Moves the plaintext session into the keychain and drops the plaintext
  /// copy — used for the first-run migration and for the retry that brings a
  /// fallback session back once the keychain works again. When either half
  /// fails the plaintext copy stays authoritative, so the two copies can never
  /// drift into overwriting each other.
  Future<void> _migrateLegacySession(String legacy) async {
    if (!await _secureWrite(legacy)) {
      // Keychain unusable: the plaintext copy is the only live session.
      _store = _storePrefs;
      await _writeStoreMarker(_storePrefs);
      return;
    }
    if (await _prefsDelete()) {
      _store = _storeSecure;
      await _writeStoreMarker(_storeSecure);
      return;
    }
    // The plaintext copy survived the migration. It stays the source of
    // truth: re-migrating it on the next launch would overwrite whatever the
    // keychain has picked up since.
    debugPrint(
      'SecureSessionStorage.initialize: plaintext session could not be '
      'removed; keeping it as the source of truth',
    );
    _store = _storePrefs;
    await _writeStoreMarker(_storePrefs);
  }

  // Every keychain / prefs call is guarded: an error (for example iOS error
  // -25308 on a background launch before first unlock) must never crash
  // Supabase.initialize and block runApp. A failed read means "no session";
  // a failed write is reported to the caller so it can pick another store.

  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;

  @override
  Future<String?> accessToken() => _serialize(() async {
    if (_signedOut) return null;
    if (_store == _storePrefs) return _prefs.getString(persistSessionKey);

    final secureValue = await _secureRead();
    if (secureValue != null) return secureValue;
    if (_store == _storeSecure) return null;

    // No store marker (older build, or a marker write that failed): the
    // keychain is preferred, and the plaintext copy is the only other place a
    // session can live.
    return _prefs.getString(persistSessionKey);
  });

  @override
  Future<void> removePersistedSession() => _serialize(() async {
    // Delete wins: the invalidation marker is written before anything is
    // deleted, so a failed delete cannot restore the account on restart.
    _signedOut = true;
    try {
      if (!await _writeSignedOutMarker(true)) {
        throw StateError('Could not persist session invalidation');
      }
    } finally {
      await _deleteStoredSession();
    }
  });

  @override
  Future<void> persistSession(String persistSessionString) =>
      _serialize(() async {
        // Order: credentials first, then the marker that names their store,
        // then the signed-out marker is cleared. The marker never points at a
        // store that does not hold the session yet.
        var inKeychain = false;
        if (_store != _storePrefs) {
          inKeychain = await _secureWrite(persistSessionString);
          if (inKeychain && await _writeStoreMarker(_storeSecure)) {
            _store = _storeSecure;
            await _prefsDelete();
            await _clearSignedOutMarker();
            return;
          }
          if (inKeychain) {
            // The marker is not durable, so a later launch cannot tell where
            // this session lives. Keep the plaintext copy as the source of
            // truth as well, instead of leaving a keychain-only session.
            debugPrint(
              'SecureSessionStorage.persistSession: store marker could not be '
              'written; falling back to the plaintext copy',
            );
          }
        }

        if (await _prefsWrite(persistSessionString)) {
          _store = _storePrefs;
          await _writeStoreMarker(_storePrefs);
          await _clearSignedOutMarker();
          return;
        }

        // Nothing durable was written. The user stays signed in for this run
        // either way; supabase_flutter ignores this future, so the failure has
        // to be visible in the logs.
        debugPrint(
          inKeychain
              ? 'SecureSessionStorage.persistSession: session is only in the '
                    'keychain; its store marker could not be written'
              : 'SecureSessionStorage.persistSession: session was not '
                    'persisted',
        );
      });

  /// A new session was stored, so the signed-out marker no longer applies.
  Future<void> _clearSignedOutMarker() async {
    _signedOut = false;
    if (await _writeSignedOutMarker(false)) return;
    debugPrint(
      'SecureSessionStorage.persistSession: signed-out marker could not be '
      'cleared; the saved session may be discarded on the next launch',
    );
  }

  Future<void> _deleteStoredSession() async {
    await _prefsDelete();
    await _secureDelete();
  }

  Future<String?> _secureRead() async {
    try {
      return await _secure.read(key: persistSessionKey);
    } catch (e) {
      debugPrint('SecureSessionStorage.accessToken: $e');
      return null;
    }
  }

  Future<bool> _secureWrite(String value) async {
    try {
      await _secure.write(key: persistSessionKey, value: value);
      return true;
    } catch (e) {
      debugPrint('SecureSessionStorage.persistSession: keychain write: $e');
      return false;
    }
  }

  Future<bool> _secureDelete() async {
    try {
      await _secure.delete(key: persistSessionKey);
      return true;
    } catch (e) {
      debugPrint('SecureSessionStorage.removePersistedSession: $e');
      return false;
    }
  }

  Future<bool> _prefsWrite(String value) async {
    try {
      return await _prefs.setString(persistSessionKey, value);
    } catch (e) {
      debugPrint('SecureSessionStorage.persistSession: plaintext write: $e');
      return false;
    }
  }

  Future<bool> _prefsDelete() async {
    try {
      return await _prefs.remove(persistSessionKey);
    } catch (e) {
      debugPrint('SecureSessionStorage.removePlaintextSession: $e');
      return false;
    }
  }

  Future<bool> _writeStoreMarker(String? store) async {
    try {
      return store == null
          ? await _prefs.remove(_storeKey)
          : await _prefs.setString(_storeKey, store);
    } catch (e) {
      debugPrint('SecureSessionStorage.storeMarker: $e');
      return false;
    }
  }

  Future<bool> _writeSignedOutMarker(bool signedOut) async {
    try {
      return await _prefs.setBool(_signedOutKey, signedOut);
    } catch (e) {
      debugPrint('SecureSessionStorage.signedOutMarker: $e');
      return false;
    }
  }

  Future<bool> _writeInstallMarker() async {
    try {
      return await _prefs.setBool(_installMarkerKey, true);
    } catch (e) {
      debugPrint('SecureSessionStorage.installMarker: $e');
      return false;
    }
  }
}
