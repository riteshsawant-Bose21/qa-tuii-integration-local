import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/services/user_session_manager.dart';

part 'session_view_model_state.dart';

class SessionViewModel extends Cubit<SessionViewModelState> {
  SessionViewModel() : super(SessionViewModelInitial());

  Future<bool> validateSession() async {
    // Placeholder logic for session validation
    // Replace with actual session validation logic
    final bool isValid = await UserSessionManager.isUserLoggedIn();
    if (isValid) {
      emit(SessionValid());
    } else {
      emit(SessionExpired());
    }

    return isValid;
  }
}
