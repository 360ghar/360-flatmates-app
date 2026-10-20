import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureKvStore {
  const SecureKvStore() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> readString(String key) => _storage.read(key: key);

  Future<void> writeString({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }

  Future<void> delete(String key) => _storage.delete(key: key);
}
