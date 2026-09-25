import 'dart:async';

import 'package:flatmates_app/core/storage/secure_session_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const key = 'sb-abc-auth-token';

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
    SharedPreferences.setMockInitialValues({
      'secure_session_install_marker': true,
    });
    FlutterSecureStorage.setMockInitialValues({key: 'current'});

    final storage = SecureSessionStorage(persistSessionKey: key);
    await storage.initialize();

    expect(await storage.accessToken(), 'current');
  });

  test(
    'failed deletion cannot restore a session after restart or migration',
    () async {
      SharedPreferences.setMockInitialValues({
        'secure_session_install_marker': true,
      });
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

      secure.failWrite = true;
      await restarted.persistSession('failed-login');
      expect(await restarted.accessToken(), isNull);
      secure.failWrite = false;
      await restarted.persistSession('new-account');
      final afterLogin = SecureSessionStorage(persistSessionKey: key);
      await afterLogin.initialize();
      expect(await afterLogin.accessToken(), 'new-account');
    },
  );

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
      SharedPreferences.setMockInitialValues({
        'secure_session_install_marker': true,
      });
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
    SharedPreferences.setMockInitialValues({
      'secure_session_install_marker': true,
    });
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
