import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/services/user_session_manager.dart';
import 'package:fusion_lib/fusion_lib.dart';

part 'session_view_model_state.dart';

class SessionViewModel extends Cubit<SessionViewModelState> {
  SessionViewModel() : super(SessionViewModelInitial());

  Future<void> skipLogin() async {
    await serviceLocator<SharedPreferencesHandler>().setBool(SharedPreferenceKeys.skipLogin, true);
    emit(SessionValid());
  }

  bool isLoginSkipped() {
    return serviceLocator<SharedPreferencesHandler>().getBool(SharedPreferenceKeys.skipLogin) ?? false;
  }

  bool hasCloudAccess() {
    final bool isSkipLogin = serviceLocator<SharedPreferencesHandler>().getBool(SharedPreferenceKeys.skipLogin) ?? false;
    //if login is skipped, cloud access is not available
    return !isSkipLogin;
  }

  Future<bool> validateSession() async {
    // Placeholder logic for session validation
    // Replace with actual session validation logic

    final bool isSkipLogin = serviceLocator<SharedPreferencesHandler>().getBool(SharedPreferenceKeys.skipLogin) ?? false;
    if (isSkipLogin) {
      emit(SessionValid());
      return true;
    }

    final bool isValid = await UserSessionManager.isUserLoggedIn();
    if (isValid) {
      emit(SessionValid());
    } else {
      emit(SessionExpired());
    }

    return isValid;
  }
}
