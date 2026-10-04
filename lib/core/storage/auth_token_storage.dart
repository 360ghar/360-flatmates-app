import 'dart:async';

import 'package:flutter/foundation.dart';

import 'secure_kv_store.dart';

final class AuthTokenStorage {
  AuthTokenStorage(this._store);

  static const _tokenKey = 'auth_token';

  final SecureKvStore _store;
  final StreamController<String?> _changes =
      StreamController<String?>.broadcast();
  Future<void> _pending = Future<void>.value();

  Stream<String?> get changes => _changes.stream;

  Future<String?> read() => _store.readString(_tokenKey);

  /// Last value written, so an unchanged token (every API request) costs no
  /// keychain write and no change event.
  String? _last;

  /// Runs [operation] after every earlier write, so a save that races a
  /// sign-out cannot land after the delete and resurrect the token. Callers
  /// observe the operation's own result and errors; the chain itself only
  /// logs, so one failure never wedges the queue.
  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>(
      (_) {},
      onError: (Object error) {
        debugPrint('AuthTokenStorage.operation: $error');
      },
    );
    return result;
  }

  Future<void> save(String token) => _serialize(() async {
    if (token == _last) return;
    await _store.writeString(key: _tokenKey, value: token);
    _last = token;
    _changes.add(token);
  });

  Future<void> clear() => _serialize(() async {
    _last = null;
    await _store.delete(_tokenKey);
    _changes.add(null);
  });

  void dispose() {
    _changes.close();
  }
}
