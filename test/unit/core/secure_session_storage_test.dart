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
