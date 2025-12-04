import 'dart:developer';

import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/services/user_profile_manager.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/service/auth/fusion_auth_service.dart';

class UserSessionManager {
  static final UserSessionManager _instance = UserSessionManager._internal();

  UserSessionManager._internal();

  factory UserSessionManager() {
    return _instance;
  }

  /// Checks if the user is signed in by verifying if the access token exists
  static String? getSignedInUserEmail() {
    // final String? userDetailsJson = serviceLocator<SharedPreferencesHandler>().getString(SharedPreferenceKeys.userDetails);
    //
    // if (userDetailsJson != null) {
    //   try {
    //     final Map<String, dynamic> jsonMap = jsonDecode(userDetailsJson);
    //     final LoginResponseEntity userDetails = LoginResponseEntity.fromJson(jsonMap);
    //     return userDetails.user.email;
    //   } catch (e) {
    //     log('Error decoding user details: $e');
    //     return null;
    //   }
    // }
    return null;
  }

  static String getInitialsFromEmail(String? email) {
    if (email == null || email.isEmpty) return '';
    final String namePart = email.split('@').first;
    return namePart.length >= 2 ? namePart.substring(0, 2).toUpperCase() : namePart.toUpperCase();
  }

  static Future<void> logout() async {
    serviceLocator<ProjectManager>().deleteFusionProjectsDirectory();
    serviceLocator<UserProfileManager>().clearUserProfile();
    final SharedPreferencesHandler prefs = serviceLocator<SharedPreferencesHandler>();
    await prefs.setBool(SharedPreferenceKeys.adminLogin, false);
    await prefs.setBool(SharedPreferenceKeys.isLoggedIn, false);
    await prefs.remove(SharedPreferenceKeys.userDetails);
    await prefs.remove(SharedPreferenceKeys.accessToken);
    log('User logged out and session cleared.');
  }

  static Future<bool> isUserLoggedIn() async {
    final String? idToken = await serviceLocator<FusionAuthService>().getIdToken();
    return idToken != null;
  }
}
