import 'dart:async';

import 'secure_kv_store.dart';

final class AuthTokenStorage {
  AuthTokenStorage(this._store);

  static const _tokenKey = 'auth_token';

  final SecureKvStore _store;
  final StreamController<String?> _changes =
      StreamController<String?>.broadcast();

  Stream<String?> get changes => _changes.stream;

  Future<String?> read() => _store.readString(_tokenKey);

  Future<void> save(String token) async {
    await _store.writeString(key: _tokenKey, value: token);
    _changes.add(token);
  }

  Future<void> clear() async {
    await _store.delete(_tokenKey);
    _changes.add(null);
  }

  void dispose() {
    _changes.close();
  }
}
