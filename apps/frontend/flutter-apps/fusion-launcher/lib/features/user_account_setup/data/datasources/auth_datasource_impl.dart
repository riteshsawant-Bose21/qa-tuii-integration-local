import 'dart:developer';

import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/utils/shared_preference_handler.dart';
import 'package:fusion_launcher/features/user_account_setup/data/models/login_response_dto.dart';
import 'package:fusion_launcher/features/user_account_setup/data/models/registration_response_dto.dart';
import 'package:fusion_launcher/features/user_account_setup/domain/entity/login_response_entity.dart';
import 'package:fusion_launcher/features/user_account_setup/domain/entity/registration_response_entity.dart';
import 'package:fusion_lib/fusion_networking/network/fusion_network_client.dart';
import 'package:fusion_lib/models/response_callback.dart';

import '../models/refresh_token_response_dto.dart';
import 'auth_datasource.dart';

class AuthDataSourceImpl implements AuthDataSource {
  final FusionNetworkClient _fusionNetworkClient;

  AuthDataSourceImpl(this._fusionNetworkClient);

  @override
  Future<ResponseCallback<LoginResponseEntity>> signInWithEmailAndPassword({required String email, required String password}) async {
    try {
      final ResponseCallback<LoginResponseDto> responseCallback = await _fusionNetworkClient.post(
        api: FusionApiEndpoint.login,
        data: <String, String>{
          'email': email,
          'password': password,
        },
        fromJson: LoginResponseDto.fromJson,
      );

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
      final ResponseCallback<RegistrationResponseDto> responseCallback = await _fusionNetworkClient.post(
        api: FusionApiEndpoint.register,
        data: <String, String>{
          'email': email,
          'password': password,
        },
        fromJson: RegistrationResponseDto.fromJson,
      );
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
      final ResponseCallback<RefreshTokenResponseDto> responseCallback = await _fusionNetworkClient.post(
        api: FusionApiEndpoint.register,
        data: <String, String>{
          "refreshToken": serviceLocator<FusionNetworkClient>().refreshToken ?? "",
        },
        fromJson: RefreshTokenResponseDto.fromJson,
      );

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
