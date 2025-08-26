import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/user_account_setup/domain/entity/login_response_entity.dart';
import 'package:fusion_launcher/features/user_account_setup/domain/entity/registration_response_entity.dart';
import 'package:fusion_lib/models/response_callback.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/use_cases/refresh_token_use_case.dart';
import '../../domain/use_cases/sign_in_use_case.dart';
import '../../domain/use_cases/sign_out_use_case.dart';
import '../../domain/use_cases/sign_up_use_case.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase signIn;
  final SignUpUseCase signUp;
  final SignOutUseCase signOut;
  final RefreshTokenUseCase refreshToken;

  AuthBloc({
    required AuthRepository repository,
  }) : signIn = SignInUseCase(repository),
       signUp = SignUpUseCase(repository),
       signOut = SignOutUseCase(repository),
       refreshToken = RefreshTokenUseCase(repository),
       super(AuthInitial()) {
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<RefreshTokenRequested>(_onRefreshTokenRequested);
  }

  Future<void> _onSignInRequested(SignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthInProgress());
    try {
      final ResponseCallback<LoginResponseEntity> loginResponse = await signIn(event.email, event.password);
      if (loginResponse.success) {
        emit(AuthSuccess());
      } else {
        emit(AuthFailure(loginResponse.message));
      }
    } catch (e) {
      log("Error during sign in: $e");
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSignUpRequested(SignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthInProgress());
    try {
      final ResponseCallback<RegistrationResponseEntity> registrationResponse = await signUp(event.email, event.password);
      if (registrationResponse.success) {
        emit(AuthSuccess());
      } else {
        emit(AuthFailure(registrationResponse.message));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSignOutRequested(SignOutRequested event, Emitter<AuthState> emit) async {
    emit(AuthInProgress());
    try {
      await signOut();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onRefreshTokenRequested(RefreshTokenRequested event, Emitter<AuthState> emit) async {
    try {
      final ResponseCallback<void> refreshTokenResponse = await refreshToken();
      if (refreshTokenResponse.success) {
        emit(AuthSuccess());
      } else {
        emit(AuthFailure(refreshTokenResponse.message));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
