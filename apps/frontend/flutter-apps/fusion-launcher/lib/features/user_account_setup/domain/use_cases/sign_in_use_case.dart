import 'dart:convert';
import 'dart:developer';

import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_utils/shared_preference_handler.dart';
import 'package:fusion_lib/models/response_callback.dart';

import '../entity/login_response_entity.dart';
import '../entity/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<ResponseCallback<LoginResponseEntity>> call(String email, String password) async {
    final SharedPreferencesHandler prefs = serviceLocator<SharedPreferencesHandler>();

    final bool isLocalAdmin = email.trim().toLowerCase() == 'admin' && password == 'admin';

    if (isLocalAdmin) {
      final LoginResponseEntity fakeResponse = LoginResponseEntity(
        user: UserEntity(
          email: 'admin@localhost',
          metadata: <String, dynamic>{},
          id: 1232,
          createdAt: DateTime.now(),
        ),
        accessToken: 'local-admin-access-token',
        refreshToken: 'local-admin-refresh-token',
        expiry: DateTime.now(),
      );

      await prefs.setString(SharedPreferenceKeys.userDetails, jsonEncode(fakeResponse.toJson()));
      await prefs.setString(SharedPreferenceKeys.accessToken, fakeResponse.accessToken);
      await prefs.setString(SharedPreferenceKeys.refreshToken, fakeResponse.refreshToken);
      await prefs.setString(SharedPreferenceKeys.expiry, fakeResponse.expiry.toString());
      await prefs.setBool(SharedPreferenceKeys.isLoggedIn, true);
      await prefs.setBool(SharedPreferenceKeys.adminLogin, true);

      log("Local admin login successful (offline mode)");

      /// Now load project AFTER SharedPreferences are written
      await serviceLocator<ProjectViewModel>().loadAllLocalProjects();
      return ResponseCallback<LoginResponseEntity>(
        success: true,
        data: fakeResponse,
        message: 'Local admin login successful (offline mode)',
      );
    }

    /// Normal API flow
    final ResponseCallback<LoginResponseEntity> responseCallback = await repository.signInWithEmailAndPassword(email: email, password: password);

    if (responseCallback.success) {
      await prefs.setString(SharedPreferenceKeys.userDetails, jsonEncode(responseCallback.data?.toJson()));
      await prefs.setString(SharedPreferenceKeys.accessToken, responseCallback.data!.accessToken);
      await prefs.setString(SharedPreferenceKeys.refreshToken, responseCallback.data!.refreshToken);
      await prefs.setString(SharedPreferenceKeys.expiry, responseCallback.data!.expiry.toString());
      await prefs.setBool(SharedPreferenceKeys.isLoggedIn, true);
      await prefs.setBool(SharedPreferenceKeys.adminLogin, false);

      /// Optional wait to ensure SharedPreferences is flushed
    }

    return responseCallback;
  }
}
