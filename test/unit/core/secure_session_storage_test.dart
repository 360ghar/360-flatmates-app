import 'dart:async';

import 'package:flatmates_app/core/storage/secure_session_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Platform interface of a transitive dependency, used only for the test-only
// store fake at the bottom of this file.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  const key = 'sb-abc-auth-token';
  const storeKey = '$key-store';
  const signedOutKey = '$key-signed-out';
  const installMarkerKey = 'secure_session_install_marker';

  test('keyForUrl matches the supabase_flutter default key', () {
    expect(
      SecureSessionStorage.keyForUrl('https://abc.supabase.co'),
      'sb-abc-auth-token',
    );
  });

  test('moves a plaintext session into secure storage on first run', () async {
    SharedPreferences.setMockInitialValues({key: '{"session":1}'});
    FlutterSecureStorage.setMockInitialValues({});

    final storage = SecureSessionStorage(persistSessionKey: key);
    await storage.initialize();

    expect(await storage.accessToken(), '{"session":1}');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(key), isFalse);
    // The marker names the store that holds the live session.
    expect(prefs.getString(storeKey), 'secure');
  });

  test(
    'a plaintext session overwrites the keychain one (it is newer)',
    () async {
      SharedPreferences.setMockInitialValues({key: 'current'});
      FlutterSecureStorage.setMockInitialValues({key: 'old'});

      final storage = SecureSessionStorage(persistSessionKey: key);
      await storage.initialize();

      expect(await storage.accessToken(), 'current');
    },
  );

  test('persist and remove round-trip through secure storage', () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final storage = SecureSessionStorage(persistSessionKey: key);
    await storage.initialize();

    await storage.persistSession('s');
    expect(await storage.hasAccessToken(), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(storeKey), 'secure');
    expect(prefs.containsKey(key), isFalse);
    await storage.removePersistedSession();
    expect(await storage.hasAccessToken(), isFalse);
  });

  test(
    'fresh install drops a keychain session left by an old install',
    () async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({key: 'from-old-install'});

      final storage = SecureSessionStorage(persistSessionKey: key);
      await storage.initialize();

      expect(await storage.hasAccessToken(), isFalse);
    },
  );

  test('later launches keep the keychain session', () async {
    SharedPreferences.setMockInitialValues({installMarkerKey: true});
    FlutterSecureStorage.setMockInitialValues({key: 'current'});

    final storage = SecureSessionStorage(persistSessionKey: key);
    await storage.initialize();

    expect(await storage.accessToken(), 'current');
  });

  test('a marked keychain session is never wiped as a fresh install', () async {
    // No install marker, but the store marker names the keychain: the session
    // was saved by this install, so the fresh-install wipe must not run.
    SharedPreferences.setMockInitialValues({storeKey: 'secure'});
    FlutterSecureStorage.setMockInitialValues({key: 'saved-session'});

    final storage = SecureSessionStorage(persistSessionKey: key);
    await storage.initialize();

    expect(await storage.accessToken(), 'saved-session');
  });

  test(
    'failed deletion cannot restore a session after restart or migration',
    () async {
      SharedPreferences.setMockInitialValues({installMarkerKey: true});
      FlutterSecureStorage.setMockInitialValues({key: 'old-account'});
      final secure = _FailingDeleteStorage();
      final storage = SecureSessionStorage(
        persistSessionKey: key,
        secure: secure,
      );
      await storage.initialize();
      await storage.removePersistedSession();
      expect(await storage.accessToken(), isNull);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, 'stale-plaintext');
      final restarted = SecureSessionStorage(
        persistSessionKey: key,
        secure: secure,
      );
      await restarted.initialize();
      expect(await restarted.accessToken(), isNull);
      expect(await restarted.hasAccessToken(), isFalse);
      expect(prefs.containsKey(key), isFalse);
    },
  );

  test(
    'a failed keychain write falls back to plaintext and records it',
    () async {
      SharedPreferences.setMockInitialValues({installMarkerKey: true});
      FlutterSecureStorage.setMockInitialValues({});
      final secure = _FailingDeleteStorage()..failWrite = true;
      final storage = SecureSessionStorage(
        persistSessionKey: key,
        secure: secure,
      );
      await storage.initialize();

      // The login is not lost: it lands in the plaintext fallback, and the
      // marker says where to find it.
      await storage.persistSession('{"session":1}');
      expect(await storage.accessToken(), '{"session":1}');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(storeKey), 'prefs');
      expect(prefs.getString(key), '{"session":1}');

      // It survives a restart while the keychain is still unusable.
      final restarted = SecureSessionStorage(
        persistSessionKey: key,
        secure: secure,
      );
      await restarted.initialize();
      expect(await restarted.accessToken(), '{"session":1}');

      // Once the keychain works again the session moves back to it and the
      // plaintext copy is dropped: the fallback is only for as long as the
      // keychain is unusable.
      final recovered = SecureSessionStorage(persistSessionKey: key);
      await recovered.initialize();
      expect(await recovered.accessToken(), '{"session":1}');
      expect(
        await const FlutterSecureStorage().read(key: key),
        '{"session":1}',
      );
      expect(prefs.getString(key), isNull);
      expect(prefs.getString(storeKey), 'secure');
    },
  );

  test('a store marker without credentials is not a session', () async {
    SharedPreferences.setMockInitialValues({
      installMarkerKey: true,
      storeKey: 'secure',
    });
    FlutterSecureStorage.setMockInitialValues({});
    final storage = SecureSessionStorage(persistSessionKey: key);
    await storage.initialize();
    expect(await storage.hasAccessToken(), isFalse);
    expect(await storage.accessToken(), isNull);

    // A marker naming the plaintext store is dropped when that copy is gone.
    SharedPreferences.setMockInitialValues({
      installMarkerKey: true,
      storeKey: 'prefs',
    });
    FlutterSecureStorage.setMockInitialValues({});
    final prefsMarker = SecureSessionStorage(persistSessionKey: key);
    await prefsMarker.initialize();
    expect(await prefsMarker.accessToken(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(storeKey), isNull);
  });

  test('a stale plaintext marker does not hide a live keychain copy', () async {
    SharedPreferences.setMockInitialValues({
      installMarkerKey: true,
      storeKey: 'prefs',
    });
    FlutterSecureStorage.setMockInitialValues({key: 'keychain-copy'});
    final storage = SecureSessionStorage(persistSessionKey: key);
    await storage.initialize();

    // The marker is dropped because the copy it named is gone, so the
    // keychain copy (the migration duplicate) is the only session left.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(storeKey), isNull);
    expect(await storage.accessToken(), 'keychain-copy');
  });

  test('the store marker wins over a leftover plaintext copy', () async {
    // A build with the failed-delete bug left this state behind: the marker
    // names the keychain, the keychain holds the newer session, and the stale
    // plaintext copy is still in SharedPreferences. Reading that copy and
    // migrating it would sign the user back in as the older account.
    SharedPreferences.setMockInitialValues({
      installMarkerKey: true,
      storeKey: 'secure',
      key: 'old-account',
    });
    FlutterSecureStorage.setMockInitialValues({key: 'new-account'});

    final storage = SecureSessionStorage(persistSessionKey: key);
    await storage.initialize();

    expect(await storage.accessToken(), 'new-account');
    expect(await const FlutterSecureStorage().read(key: key), 'new-account');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(key), isNull);
    expect(prefs.getString(storeKey), 'secure');
  });

  test(
    'a failed plaintext delete never leaves the marker naming the keychain',
    () async {
      SharedPreferences.setMockInitialValues({installMarkerKey: true});
      final store = _FailingRemovePrefsStore(
        SharedPreferencesStorePlatform.instance,
      );
      SharedPreferencesStorePlatform.instance = store;
      SharedPreferences.resetStatic();
      FlutterSecureStorage.setMockInitialValues({});

      final storage = SecureSessionStorage(persistSessionKey: key);
      await storage.initialize();

      // The stale copy a failed delete leaves behind, while the marker already
      // names the keychain.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, 'old-account');

      // The platform rejects the plaintext delete for the rest of this test.
      store.failRemove = true;
      await storage.persistSession('new-account');

      // The marker must not say `secure` while the plaintext copy is live: the
      // next launch reads that copy and migrates it over the newer keychain
      // token.
      expect(prefs.getString(storeKey), 'prefs');
      expect(prefs.getString(key), 'new-account');
      expect(await storage.accessToken(), 'new-account');

      // The end-to-end invariant: a restart never resurrects the old session.
      store.failRemove = false;
      SharedPreferences.resetStatic();
      final restarted = SecureSessionStorage(persistSessionKey: key);
      await restarted.initialize();

      expect(await restarted.accessToken(), 'new-account');
      expect(await const FlutterSecureStorage().read(key: key), 'new-account');
    },
  );

  test('a signed-out marker suppresses a leftover keychain session', () async {
    SharedPreferences.setMockInitialValues({
      installMarkerKey: true,
      signedOutKey: true,
      storeKey: 'secure',
    });
    FlutterSecureStorage.setMockInitialValues({key: 'leftover'});

    final storage = SecureSessionStorage(persistSessionKey: key);
    await storage.initialize();

    expect(await storage.hasAccessToken(), isFalse);
    expect(await storage.accessToken(), isNull);
  });

  test('a session saved after sign-out clears the invalidation', () async {
    SharedPreferences.setMockInitialValues({installMarkerKey: true});
    FlutterSecureStorage.setMockInitialValues({});
    final storage = SecureSessionStorage(persistSessionKey: key);
    await storage.initialize();

    await storage.persistSession('first');
    await storage.removePersistedSession();
    expect(await storage.accessToken(), isNull);

    await storage.persistSession('second');
    expect(await storage.accessToken(), 'second');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(signedOutKey), isFalse);
    expect(prefs.getString(storeKey), 'secure');

    final restarted = SecureSessionStorage(persistSessionKey: key);
    await restarted.initialize();
    expect(await restarted.accessToken(), 'second');
  });

  test(
    'sign-out in plaintext fallback also invalidates the old keychain session',
    () async {
      SharedPreferences.setMockInitialValues({key: 'plaintext-account'});
      FlutterSecureStorage.setMockInitialValues({key: 'old-keychain-account'});
      final secure = _FailingDeleteStorage()..failWrite = true;
      final fallback = SecureSessionStorage(
        persistSessionKey: key,
        secure: secure,
      );
      await fallback.initialize();
      expect(await fallback.accessToken(), 'plaintext-account');
      await fallback.removePersistedSession();
      final restarted = SecureSessionStorage(
        persistSessionKey: key,
        secure: secure,
      );
      await restarted.initialize();
      expect(await restarted.accessToken(), isNull);
      await fallback.persistSession('new-fallback-account');
      final recovered = SecureSessionStorage(persistSessionKey: key);
      await recovered.initialize();
      expect(await recovered.accessToken(), 'new-fallback-account');
    },
  );

  test(
    'sign-out waits for an earlier session write before invalidation',
    () async {
      SharedPreferences.setMockInitialValues({installMarkerKey: true});
      FlutterSecureStorage.setMockInitialValues({key: 'old'});
      final secure = _FailingDeleteStorage()..writeGate = Completer<void>();
      final storage = SecureSessionStorage(
        persistSessionKey: key,
        secure: secure,
      );
      await storage.initialize();
      final refresh = storage.persistSession('refreshed');
      final signOut = storage.removePersistedSession();
      secure.writeGate!.complete();
      await Future.wait([refresh, signOut]);
      final restarted = SecureSessionStorage(
        persistSessionKey: key,
        secure: secure,
      );
      await restarted.initialize();
      expect(await restarted.accessToken(), isNull);
    },
  );

  test('keychain errors never throw out of the storage', () async {
    SharedPreferences.setMockInitialValues({installMarkerKey: true});
    final storage = SecureSessionStorage(
      persistSessionKey: key,
      secure: const _ThrowingSecureStorage(),
    );
    await storage.initialize();

    expect(await storage.hasAccessToken(), isFalse);
    expect(await storage.accessToken(), isNull);
    await storage.persistSession('s');
    await storage.removePersistedSession();
  });
}

/// Simulates a locked keychain: every call fails.
class _ThrowingSecureStorage extends FlutterSecureStorage {
  const _ThrowingSecureStorage();

  static final _error = Exception('-25308 errSecInteractionNotAllowed');

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) => Future.error(_error);

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) => Future.error(_error);

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) => Future.error(_error);

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) => Future.error(_error);
}

class _FailingDeleteStorage extends FlutterSecureStorage {
  bool failWrite = false;
  Completer<void>? writeGate;

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw StateError('Temporary keychain delete failure');
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failWrite) throw StateError('Temporary keychain write failure');
    await writeGate?.future;
    await super.write(key: key, value: value);
  }
}

/// Wraps the installed SharedPreferences platform store and can make `remove`
/// fail, so a test can simulate a plaintext delete that never reaches the
/// platform (the store keeps the value while `SharedPreferences.remove`
/// reports false).
class _FailingRemovePrefsStore extends SharedPreferencesStorePlatform {
  _FailingRemovePrefsStore(this._delegate);

  final SharedPreferencesStorePlatform _delegate;
  bool failRemove = false;

  @override
  Future<bool> remove(String key) async =>
      failRemove ? false : _delegate.remove(key);

  @override
  Future<bool> setValue(String valueType, String key, Object value) =>
      _delegate.setValue(valueType, key, value);

  @override
  Future<bool> clear() => _delegate.clear();

  @override
  Future<Map<String, Object>> getAll() => _delegate.getAll();
}
