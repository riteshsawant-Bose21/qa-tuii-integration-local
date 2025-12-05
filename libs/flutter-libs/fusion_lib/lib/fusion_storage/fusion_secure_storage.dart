abstract class FusionSecureStorage {
  Future<void> saveToken(StorageKey key, String value);
  Future<String?> getToken(StorageKey key);
  Future<void> deleteToken(StorageKey key);
  Future<void> clearAll();
}

enum StorageKey {
  accessToken,
  refreshToken,
  idToken,
  expiredAt,
  userEmail,
  userName,
  userProfile,
}

extension StorageKeyExtension on StorageKey {
  String get key {
    switch (this) {
      case StorageKey.accessToken:
        return "access_token";
      case StorageKey.refreshToken:
        return "refresh_token";
      case StorageKey.idToken:
        return "id_token";
      case StorageKey.expiredAt:
        return "expired_at";
      case StorageKey.userEmail:
        return "user_email";
      case StorageKey.userName:
        return "user_name";
      case StorageKey.userProfile:
        return "user_profile";
    }
  }
}
