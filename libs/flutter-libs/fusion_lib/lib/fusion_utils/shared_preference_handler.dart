import 'package:shared_preferences/shared_preferences.dart';

/// Singleton class for managing key-value storage using `SharedPreferences`.
///
/// Provides methods to set, get, and remove values of different types.
///
/// # Example
///
/// ```
/// final prefsHandler = SharedPreferencesHandler.getInstance();
/// await prefsHandler.setString(SharedPreferenceKeys.fusionIpAddress, "192.168.0.1");
/// String? ip = prefsHandler.getString(SharedPreferenceKeys.fusionIpAddress);
/// ```
class SharedPreferencesHandler {
  static SharedPreferencesHandler? _instance;
  final SharedPreferences _prefs;

  SharedPreferencesHandler._(this._prefs);

  static SharedPreferencesHandler getInstance(SharedPreferences prefs) {
    _instance ??= SharedPreferencesHandler._(prefs);
    return _instance!;
  }

  Future<bool> setString(SharedPreferenceKeys sharedPreferenceKey, String value) async {
    return _prefs.setString(sharedPreferenceKey.key, value);
  }

  String? getString(SharedPreferenceKeys sharedPreferenceKey) {
    return _prefs.getString(sharedPreferenceKey.key);
  }

  Future<bool> setStringList(SharedPreferenceKeys sharedPreferenceKey, List<String> value) async {
    return _prefs.setStringList(sharedPreferenceKey.key, value);
  }

  List<String>? getStringList(SharedPreferenceKeys sharedPreferenceKey) {
    return _prefs.getStringList(sharedPreferenceKey.key);
  }

  Future<bool> setBool(SharedPreferenceKeys sharedPreferenceKey, bool value) async {
    return _prefs.setBool(sharedPreferenceKey.key, value);
  }

  bool? getBool(SharedPreferenceKeys sharedPreferenceKey) {
    return _prefs.getBool(sharedPreferenceKey.key);
  }

  /// Sets an integer value for the given key.
  Future<bool> setInt(SharedPreferenceKeys sharedPreferenceKey, int value) async {
    return _prefs.setInt(sharedPreferenceKey.key, value);
  }

  int? getInt(SharedPreferenceKeys sharedPreferenceKey) {
    return _prefs.getInt(sharedPreferenceKey.key);
  }

  Future<bool> remove(SharedPreferenceKeys sharedPreferenceKey) async {
    return _prefs.remove(sharedPreferenceKey.key);
  }

  Future<bool> clearAll() async {
    return _prefs.clear();
  }
}

enum SharedPreferenceKeys {
  appSettings, //TODO: need to rename this key
  themeMode,
  lastProjectSyncTime,
}

extension SharedPreferenceKeysExtension on SharedPreferenceKeys {
  String get key {
    switch (this) {
      case SharedPreferenceKeys.appSettings:
        return 'app_settings';
      case SharedPreferenceKeys.themeMode:
        return 'theme_mode';
      case SharedPreferenceKeys.lastProjectSyncTime:
        return 'last_project_sync_time';
    }
  }
}
