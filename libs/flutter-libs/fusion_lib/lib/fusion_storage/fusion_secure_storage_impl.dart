import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'fusion_secure_storage.dart';

class FusionSecureStorageImpl implements FusionSecureStorage {
  final FlutterSecureStorage _storage;

  FusionSecureStorageImpl(this._storage);

  @override
  Future<void> saveToken(StorageKey key, String value) async {
    await _storage.write(key: key.key, value: value);
  }

  @override
  Future<String?> getToken(StorageKey key) async {
    return await _storage.read(key: key.key);
  }

  @override
  Future<void> deleteToken(StorageKey key) async {
    await _storage.delete(key: key.key);
  }

  @override
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
