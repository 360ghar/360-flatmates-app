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

  test('keeps an existing secure session over a stale plaintext one', () async {
    SharedPreferences.setMockInitialValues({key: 'old'});
    FlutterSecureStorage.setMockInitialValues({key: 'current'});

    final storage = SecureSessionStorage(persistSessionKey: key);
    await storage.initialize();

    expect(await storage.accessToken(), 'current');
  });

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
}
