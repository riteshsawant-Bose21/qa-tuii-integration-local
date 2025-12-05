import 'dart:convert';
import 'dart:developer';

import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/services/user_profile_manager.dart';
import 'package:fusion_launcher/features/authentication/viewmodel/auth_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/service/auth/fusion_auth_service.dart';

class UserSessionManager {
  static final UserSessionManager _instance = UserSessionManager._internal();

  UserSessionManager._internal();

  factory UserSessionManager() {
    return _instance;
  }

  static UserModel? _cachedUserModel;

  static Future<UserModel?> getSignedInUserProfile() async {
    if (_cachedUserModel != null) {
      return _cachedUserModel;
    }

    final String? userDetailsJson = await serviceLocator<FusionSecureStorage>().getToken(StorageKey.userProfile);

    if (userDetailsJson != null) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(userDetailsJson);
        final UserModel userDetails = UserModel.fromJson(jsonMap);
        _cachedUserModel = userDetails;

        return userDetails;
      } catch (e) {
        log('Error decoding user details: $e');
        return null;
      }
    }
    return null;
  }

  void saveUserProfile(UserModel userModel) {
    _cachedUserModel = userModel;
    final String userDetailsJson = jsonEncode(userModel.toJson());
    serviceLocator<FusionSecureStorage>().saveToken(StorageKey.userProfile, userDetailsJson);
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
    await serviceLocator<AuthViewModel>().logout();
    _cachedUserModel = null;
    await serviceLocator<ProjectManager>().deleteFusionProjectsDirectory();
    serviceLocator<UserProfileManager>().clearUserProfile();
    final SharedPreferencesHandler prefs = serviceLocator<SharedPreferencesHandler>();
    await prefs.clearAll();
  }

  static Future<bool> isUserLoggedIn() async {
    final String? idToken = await serviceLocator<FusionAuthService>().getIdToken();
    return idToken != null;
  }
}
