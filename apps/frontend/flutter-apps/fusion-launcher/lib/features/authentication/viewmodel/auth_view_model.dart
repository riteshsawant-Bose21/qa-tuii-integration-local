import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/authentication/viewmodel/session_view_model.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/service/auth/fusion_auth_service.dart';

import '../../../core/services/user_session_manager.dart';

part 'auth_view_model_state.dart';

class AuthViewModel extends Cubit<AuthViewModelState> {
  final FusionAuthService _authService;
  final FusionNetworkClient _networkClient;
  final SessionViewModel sessionViewModel;

  AuthViewModel({
    required FusionAuthService authService,
    required FusionNetworkClient networkClient,
    required this.sessionViewModel,
  }) : _authService = authService,
       _networkClient = networkClient,
       super(AuthViewModelInitial());

  /// Emit loading state
  void _emitLoading() {
    emit(AuthLoading());
  }

  /// Emit authenticated state
  void _emitAuthenticated() {
    emit(Authenticated());
    sessionViewModel.validateSession();
  }

  /// Emit unauthenticated state
  void _emitUnauthenticated() {
    emit(Unauthenticated());
    sessionViewModel.validateSession();
  }

  /// Emit error state
  void _emitError(
    String message,
  ) {
    emit(AuthError(message));
    sessionViewModel.validateSession();
  }

  /// Emit web redirect in progress state
  void _emitWebRedirectInProgress() {
    emit(AuthWebRedirectInProgress());
  }

  // /// Initialize and check if user is already authenticated
  Future<void> initialize() async {
    try {
      _emitLoading();

      // Check if user is already authenticated
      final bool isAuthenticated = await _authService.isAuthenticated();

      if (isAuthenticated) {
        //todo: Uncomment and implement user details fetching from backend
        /*   final UserModel? savedProfile = await UserSessionManager.getSignedInUserProfile();
        if (savedProfile != null) {*/
        _emitAuthenticated();
        /*        } else {
          // If no saved profile, treat as unauthenticated
          _emitUnauthenticated();
        }*/
      } else {
        _emitUnauthenticated();
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
      _emitError('Failed to initialize: ${e.toString()}');
    }
  }

  /// Login
  Future<void> login() async {
    try {
      _emitLoading();
      final Credentials credentials = await _authService.login();

      await serviceLocator<SharedPreferencesHandler>().setBool(SharedPreferenceKeys.skipLogin, false);

      await _handleLoginSuccess(credentials);
    } on Exception catch (e) {
      // Web redirect initiated - this is expected
      if (kIsWeb && e.toString().contains('Web redirect initiated')) {
        _emitWebRedirectInProgress();
        return;
      }

      FusionLogger.log(tag: LogTag.exceptions, message: 'Login error: $e');
      _emitError('Login failed: ${e.toString()}');
    }
  }

  /// Handle login success
  Future<void> _handleLoginSuccess(Credentials credentials) async {
    try {
      // Get user authorization from backend
      final ResponseCallback<UserModel> authDataResponse = await getUserDetails();

      FusionLogger.log(tag: LogTag.exceptions, message: "User authorization: response received ${authDataResponse.success} ");

      if (authDataResponse.success) {
        emit(Authenticated());

        // ==== TEMPORARY IMPLEMENTATION ====
        UserSessionManager().saveUserProfile(
          UserModel(
            account: UserAccount(
              id: credentials.user.sub,
              description: credentials.user.email,
              name: credentials.user.name,
              type: 'email',
            ),
            user: UserData(
              id: credentials.user.sub,
              email: credentials.user.email,
            ),
          ),
        );
      } else {
        await serviceLocator<FusionSecureStorage>().clearAll();
        logout();
        // _emitError('Failed to get user details: ${authDataResponse.message}'));
      }
    } catch (e) {
      FusionLogger.log(tag: LogTag.exceptions, message: 'Get user authorization error: $e');
      _emitError('Failed to get user details: ${e.toString()}');
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      _emitLoading();

      final bool hasCloudAccess = serviceLocator<SessionViewModel>().hasCloudAccess();

      if (hasCloudAccess) {
        await _authService.logout();
      }
      await serviceLocator<FusionSecureStorage>().clearAll();
      await serviceLocator<SharedPreferencesHandler>().clearAll();
      await serviceLocator<ProjectViewModel>().deleteFusionProjectDirectory();

      _emitUnauthenticated();
    } catch (e) {
      FusionLogger.log(tag: LogTag.exceptions, message: 'Logout error: $e');
      _emitError('Logout failed: ${e.toString()}');
    }
  }

  /// Refresh authentication
  Future<void> refreshAuth() async {
    try {
      final String? refreshToken = await _authService.getRefreshToken();
      if (refreshToken == null) {
        _emitUnauthenticated();
        return;
      }

      // Implement token refresh logic here if your Auth0 setup supports it
      // For now, just check if tokens exist
      final bool isAuthenticated = await _authService.isAuthenticated();
      if (!isAuthenticated) {
        _emitUnauthenticated();
      }
    } catch (e) {
      FusionLogger.log(tag: LogTag.exceptions, message: 'Refresh auth error: $e');
      _emitError('Failed to refresh authentication: ${e.toString()}');
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
