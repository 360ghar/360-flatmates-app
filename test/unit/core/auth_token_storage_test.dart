import 'package:flatmates_app/core/storage/auth_token_storage.dart';
import 'package:flatmates_app/core/storage/secure_kv_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('an unchanged token costs no write and no change event', () async {
    final storage = AuthTokenStorage(const SecureKvStore());
    final events = <String?>[];
    final subscription = storage.changes.listen(events.add);

    await storage.save('t1');
    await storage.save('t1');
    await storage.clear();
    await Future<void>.delayed(Duration.zero);

    expect(events, ['t1', null]);
    expect(await storage.read(), isNull);
    await subscription.cancel();
    storage.dispose();
  });

  test('a save racing a clear cannot resurrect the token', () async {
    final storage = AuthTokenStorage(const SecureKvStore());
    final events = <String?>[];
    final subscription = storage.changes.listen(events.add);

    // A token refresh and a sign-out started without awaiting each other.
    final save = storage.save('t1');
    final clear = storage.clear();
    await Future.wait([save, clear]);
    await Future<void>.delayed(Duration.zero);

    // Delete wins, and the events stay in the order the calls were made.
    expect(await storage.read(), isNull);
    expect(events, ['t1', null]);

    // `_last` must not still hold the token, or this save returns early and
    // the store stays empty.
    await storage.save('t1');
    expect(await storage.read(), 't1');

    await subscription.cancel();
    storage.dispose();
  });
}
