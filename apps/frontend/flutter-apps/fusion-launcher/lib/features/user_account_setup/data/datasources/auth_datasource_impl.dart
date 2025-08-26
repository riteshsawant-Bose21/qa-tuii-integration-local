import 'dart:developer';

import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/user_account_setup/domain/entity/login_response_entity.dart';
import 'package:fusion_launcher/features/user_account_setup/domain/entity/registration_response_entity.dart';
import 'package:fusion_lib/fusion_auth/fusion_auth.dart';
import 'package:fusion_lib/fusion_utils/shared_preference_handler.dart';
import 'package:fusion_lib/models/fusion_auth/login_response_dto.dart';
import 'package:fusion_lib/models/fusion_auth/refresh_token_response_dto.dart';
import 'package:fusion_lib/models/fusion_auth/registration_response_dto.dart';
import 'package:fusion_lib/models/response_callback.dart';

import 'auth_datasource.dart';

class AuthDataSourceImpl implements AuthDataSource {
  final FusionAuth fusionAuth;
  AuthDataSourceImpl({required this.fusionAuth});

  @override
  Future<ResponseCallback<LoginResponseEntity>> signInWithEmailAndPassword({required String email, required String password}) async {
    try {
      /// Using FusionAuth for login
      final ResponseCallback<LoginResponseDto> responseCallback = await fusionAuth.signIn(email: email, password: password);

      log("responseCallback.message======${responseCallback.message}");

      if (responseCallback.success) {
        return ResponseCallback<LoginResponseEntity>(
          success: true,
          data: LoginResponseEntity.fromDto(responseCallback.data!),
          message: responseCallback.message,
        );
      } else {
        return ResponseCallback<LoginResponseEntity>(
          success: false,
          message: responseCallback.message,
        );
      }
    } catch (e) {
      return ResponseCallback<LoginResponseEntity>(
        success: false,
        message: 'Error signing in: $e',
      );
    }
  }

  @override
  Future<ResponseCallback<RegistrationResponseEntity>> signUpWithEmailAndPassword({required String email, required String password}) async {
    try {
      /// Using FusionAuth for registration
      final ResponseCallback<RegistrationResponseDto> responseCallback = await fusionAuth.signUp(email: email, password: password);
      if (responseCallback.success) {
        return ResponseCallback<RegistrationResponseEntity>(
          success: true,
          data: RegistrationResponseEntity.fromDto(responseCallback.data!),
          message: responseCallback.message,
        );
      } else {
        return ResponseCallback<RegistrationResponseEntity>(
          success: false,
          message: responseCallback.message,
        );
      }
    } catch (e) {
      return ResponseCallback<RegistrationResponseEntity>(
        success: false,
        message: 'Error signing up: $e',
      );
    }
  }

  @override
  Future<void> signOut() async {
    //clear the tokens from the FusionNetworkClient and shared preferences if any
  }

  @override
  Future<ResponseCallback<void>> refreshToken() async {
    try {
      /// Using FusionAuth for refreshing token
      final ResponseCallback<RefreshTokenResponseDto> responseCallback = await fusionAuth.refreshToken();

      if (responseCallback.success) {
        serviceLocator<SharedPreferencesHandler>().setString(SharedPreferenceKeys.accessToken, responseCallback.data!.accessToken);
        serviceLocator<SharedPreferencesHandler>().setString(SharedPreferenceKeys.expiry, responseCallback.data!.expiryTime.toString());
      }

      return responseCallback;
    } catch (e) {
      return ResponseCallback<RefreshTokenResponseDto>(
        success: false,
        message: 'Error refreshing token: $e',
      );
    }
  }
}
