import 'package:fusion_lib/models/response_callback.dart';

import '../fusion_networking/network/fusion_network_client.dart';
import '../models/fusion_auth/login_response_dto.dart';
import '../models/fusion_auth/refresh_token_response_dto.dart';
import '../models/fusion_auth/registration_response_dto.dart';
import 'fusion_auth.dart';

class FusionAuthImpl implements FusionAuth {
  final FusionNetworkClient _fusionNetworkClient;

  FusionAuthImpl({required FusionNetworkClient fusionNetworkClient}) : _fusionNetworkClient = fusionNetworkClient;

  /// Sign in with email and password
  @override
  Future<ResponseCallback<LoginResponseDto>> signIn({required String email, required String password}) async {
    final ResponseCallback<LoginResponseDto> responseCallback = await _fusionNetworkClient.post(
      api: FusionApiEndpoint.login,
      data: <String, String>{'email': email.trim(), 'password': password},
      fromJson: LoginResponseDto.fromJson,
    );
    return responseCallback;
  }

  /// Sign up with email and password
  @override
  Future<ResponseCallback<RegistrationResponseDto>> signUp({required String email, required String password}) async {
    final ResponseCallback<RegistrationResponseDto> responseCallback = await _fusionNetworkClient.post(
      api: FusionApiEndpoint.register,
      data: <String, String>{'email': email, 'password': password},
      fromJson: RegistrationResponseDto.fromJson,
    );

    return responseCallback;
  }

  /// Refresh the access token using the refresh token
  @override
  Future<ResponseCallback<RefreshTokenResponseDto>> refreshToken() async {
    final ResponseCallback<RefreshTokenResponseDto> responseCallback = await _fusionNetworkClient.post(
      api: FusionApiEndpoint.register,
      data: <String, String>{"refreshToken": _fusionNetworkClient.refreshToken ?? ""},
      fromJson: RefreshTokenResponseDto.fromJson,
    );

    return responseCallback;
  }
}
