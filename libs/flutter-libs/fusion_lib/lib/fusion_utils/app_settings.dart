//singleton app settings model class

import 'dart:convert';

import 'package:fusion_lib/di/service_locator.dart';
import 'package:fusion_lib/fusion_utils/shared_preference_handler.dart';

class FusionPreferences {
  /// Create a Singleton class instance
  static final FusionPreferences _instance = FusionPreferences._internal();

  /// internal constructor to prevent external instantiation of the class
  FusionPreferences._internal();

  /// Factory constructor to return the singleton instance
  factory FusionPreferences() {
    fromPreferences();
    return _instance;
  }

  static String _droServerUrl = '';
  static String _fusionCloudBackEndUrl = '';
  static String _cloudWebUrl = '';

  //virtual ip of selected project
  String virtualIp = '';

  String get droServerUrl {
    if (_droServerUrl.isEmpty) {
      fromPreferences();
    }
    return _droServerUrl;
  }

  String get fusionCloudBackendUrl {
    if (_fusionCloudBackEndUrl.isEmpty) {
      fromPreferences();
    }
    return _fusionCloudBackEndUrl;
  }

  String get cloudWebUrl {
    if (_cloudWebUrl.isEmpty) {
      fromPreferences();
    }
    return _cloudWebUrl;
  }

  void setDroServerUrl(String url) {
    _droServerUrl = url;
    saveToPreferences();
  }

  void setFusionCloudBackendUrl(String url) {
    _fusionCloudBackEndUrl = url;
    saveToPreferences();
  }

  void setCloudWebUrl(String url) {
    _cloudWebUrl = url;
    saveToPreferences();
  }

  void saveToPreferences() async {
    // Implement saving settings to shared preferences or any other storage

    final Map<String, dynamic> settings = <String, dynamic>{
      'droServerUrl': _droServerUrl,
      'fusionCloudUrl': _fusionCloudBackEndUrl,
      'cloudWebUrl': _cloudWebUrl,
    };

    await fusionLibLocator<SharedPreferencesHandler>().setString(SharedPreferenceKeys.appSettings, jsonEncode(settings));
  }

  static void fromPreferences() {
    final String? settingsJson = fusionLibLocator<SharedPreferencesHandler>().getString(SharedPreferenceKeys.appSettings);
    if (settingsJson != null) {
      final Map<String, dynamic> settings = jsonDecode(settingsJson);
      _droServerUrl = settings['droServerUrl'] ?? '';
      _fusionCloudBackEndUrl = settings['fusionCloudUrl'] ?? '';
      _cloudWebUrl = settings['cloudWebUrl'] ?? '';
    }
  }
}
