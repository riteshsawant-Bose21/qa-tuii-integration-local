import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:fusion_launcher/core/services/user_session_manager.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:fusion_lib/service/auth/fusion_auth_service.dart';

part 'auth_view_model_state.dart';

class AuthViewModel extends Cubit<AuthViewModelState> {
  final FusionAuthService _authService;
  final FusionNetworkClient _networkClient;

  AuthViewModel({
    required FusionAuthService authService,
    required FusionNetworkClient networkClient,
  }) : _authService = authService,
       _networkClient = networkClient,
       super(AuthViewModelInitial());

  // /// Initialize and check if user is already authenticated
  Future<void> initialize() async {
    try {
      emit(AuthLoading());

      // Check if user is already authenticated
      final bool isAuthenticated = await _authService.isAuthenticated();

      if (isAuthenticated) {
        final String? idToken = await _authService.getIdToken();
        if (idToken != null) {
          // Get user details from backend
          // final Map<String, dynamic> authData = await _authService.getUserAuthorization(idToken);

          // You might need to get user profile from stored data or API
          // For now, emit authenticated state
          emit(Authenticated());
        } else {
          emit(Unauthenticated());
        }
      } else {
        emit(Unauthenticated());
      }

      // Listen for web redirect on web platform
      if (kIsWeb) {
        final Credentials? credentials = await _authService.initializeWebAuth();
        if (credentials != null) {
          await _handleLoginSuccess(credentials);
        }
      }
    } catch (e) {
      FusionLogger.log(tag: LogTag.exceptions, message: 'Initialize error: $e');
      emit(AuthError('Failed to initialize: ${e.toString()}'));
      emit(Unauthenticated());
    }
  }

  /// Login
  Future<void> login() async {
    try {
      emit(AuthLoading());

      final Credentials credentials = await _authService.login();

      await _handleLoginSuccess(credentials);
    } on Exception catch (e) {
      // Web redirect initiated - this is expected
      if (kIsWeb && e.toString().contains('Web redirect initiated')) {
        emit(AuthWebRedirectInProgress());
        return;
      }

      FusionLogger.log(tag: LogTag.exceptions, message: 'Login error: $e');
      emit(AuthError('Login failed: ${e.toString()}'));
      emit(Unauthenticated());
    }
  }

  /// Handle login success
  Future<void> _handleLoginSuccess(Credentials credentials) async {
    try {
      // FusionLogger.log(tag: LogTag.exceptions, message: "Email: ${credentials.user.email}");
      // FusionLogger.log(tag: LogTag.exceptions, message: "Access Token: ${credentials.accessToken}");
      // FusionLogger.log(tag: LogTag.exceptions, message: "ID Token: ${credentials.idToken}");

      // Get user authorization from backend
      final ResponseCallback<UserModel> authDataResponse = await getUserDetails();

      FusionLogger.log(tag: LogTag.exceptions, message: "User authorization: response received ${authDataResponse.success} ");

      if (authDataResponse.success && authDataResponse.data != null) {
        UserSessionManager().saveUserProfile(authDataResponse.data!);
        emit(
          Authenticated(),
        );
      } else {
        logout();
        // emit(AuthError('Failed to get user details: ${authDataResponse.message}'));
      }
    } catch (e) {
      FusionLogger.log(tag: LogTag.exceptions, message: 'Get user authorization error: $e');
      emit(AuthError('Failed to get user details: ${e.toString()}'));
      emit(Unauthenticated());
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      emit(AuthLoading());

      await _authService.logout();

      emit(Unauthenticated());
    } catch (e) {
      FusionLogger.log(tag: LogTag.exceptions, message: 'Logout error: $e');
      emit(AuthError('Logout failed: ${e.toString()}'));
      // Still set to unauthenticated even if logout fails
      emit(Unauthenticated());
    }
  }

  /// Refresh authentication
  Future<void> refreshAuth() async {
    try {
      final String? refreshToken = await _authService.getRefreshToken();
      if (refreshToken == null) {
        emit(Unauthenticated());
        return;
      }

      // Implement token refresh logic here if your Auth0 setup supports it
      // For now, just check if tokens exist
      final bool isAuthenticated = await _authService.isAuthenticated();
      if (!isAuthenticated) {
        emit(Unauthenticated());
      }
    } catch (e) {
      FusionLogger.log(tag: LogTag.exceptions, message: 'Refresh auth error: $e');
      emit(Unauthenticated());
    }
  }

  Future<ResponseCallback<UserModel>> getUserDetails() async {
    final ResponseCallback<UserModel> response = await _networkClient.get(
      api: FusionApiEndpoint.getProfile,
      fromJson: (Map<String, dynamic> json) => UserModel.fromJson(json),
    );
    return response;
  }
}
