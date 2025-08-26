//singleton app settings model class

import 'dart:convert';

import 'package:fusion_lib/fusion_utils/shared_preference_handler.dart';

class FusionPreferences {
  final SharedPreferencesHandler sharedPreferencesHandler;

  FusionPreferences({required this.sharedPreferencesHandler}) {
    fromPreferences();
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

    await sharedPreferencesHandler.setString(SharedPreferenceKeys.appSettings, jsonEncode(settings));
  }

  void fromPreferences() {
    final String? settingsJson = sharedPreferencesHandler.getString(SharedPreferenceKeys.appSettings);
    if (settingsJson != null) {
      final Map<String, dynamic> settings = jsonDecode(settingsJson);
      _droServerUrl = settings['droServerUrl'] ?? '';
      _fusionCloudBackEndUrl = settings['fusionCloudUrl'] ?? '';
      _cloudWebUrl = settings['cloudWebUrl'] ?? '';
    }
  }
}
