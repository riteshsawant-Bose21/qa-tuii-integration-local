import 'package:shared_preferences/shared_preferences.dart';

import '../di/service_locator.dart';

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

  static SharedPreferencesHandler getInstance() {
    if (_instance == null) {
      final SharedPreferences prefs = fusionLibLocator<SharedPreferences>();
      _instance = SharedPreferencesHandler._(prefs);
    }
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
  fusionIpAddress,
  droIpAddress,
  appSettings, //TODO: need to rename this key
  themeMode,
  onboardingStatus,
  bleDeviceId,
  fusionLocations,
  userDetails,
  accessToken,
  refreshToken,
  expiry,
  isLoggedIn,
  adminLogin, // This is for local admin login
}

extension SharedPreferenceKeysExtension on SharedPreferenceKeys {
  String get key {
    switch (this) {
      case SharedPreferenceKeys.fusionIpAddress:
        return 'fusion_ip_address';
      case SharedPreferenceKeys.droIpAddress:
        return 'dro_ip_address';
      case SharedPreferenceKeys.appSettings:
        return 'app_settings';
      case SharedPreferenceKeys.themeMode:
        return 'theme_mode';
      case SharedPreferenceKeys.onboardingStatus:
        return "onboarding_status";
      case SharedPreferenceKeys.bleDeviceId:
        return "ble_remote_id";
      case SharedPreferenceKeys.fusionLocations:
        return "fusion_locations";
      case SharedPreferenceKeys.userDetails:
        return "user_details";
      case SharedPreferenceKeys.accessToken:
        return "access_token";
      case SharedPreferenceKeys.refreshToken:
        return "refresh_token";
      case SharedPreferenceKeys.expiry:
        return "expiry";
      case SharedPreferenceKeys.isLoggedIn:
        return "is_logged_in";
      case SharedPreferenceKeys.adminLogin:
        return "admin_login";
    }
  }
}
