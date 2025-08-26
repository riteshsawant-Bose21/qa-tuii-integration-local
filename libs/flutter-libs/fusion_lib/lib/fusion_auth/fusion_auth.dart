import '../models/fusion_auth/login_response_dto.dart';
import '../models/fusion_auth/refresh_token_response_dto.dart';
import '../models/fusion_auth/registration_response_dto.dart';
import '../models/response_callback.dart';

abstract class FusionAuth {
  Future<ResponseCallback<LoginResponseDto>> signIn({required String email, required String password});

  Future<ResponseCallback<RegistrationResponseDto>> signUp({required String email, required String password});

  Future<ResponseCallback<RefreshTokenResponseDto>> refreshToken();
}
