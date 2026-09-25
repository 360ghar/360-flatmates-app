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

  /// Last value written, so an unchanged token (every API request) costs no
  /// keychain write and no change event.
  String? _last;

  Future<void> save(String token) async {
    if (token == _last) return;
    await _store.writeString(key: _tokenKey, value: token);
    _last = token;
    _changes.add(token);
  }

  Future<void> clear() async {
    _last = null;
    await _store.delete(_tokenKey);
    _changes.add(null);
  }

  void dispose() {
    _changes.close();
  }
}
