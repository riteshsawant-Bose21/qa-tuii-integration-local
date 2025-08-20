// login_response.dart
import 'package:fusion_launcher/features/user_account_setup/data/models/user_dto.dart';

/// DTO classes
class LoginResponseDto {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserDto user;

  LoginResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: 0,
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expiresIn': expiresIn,
      'user': user.toJson(),
    };
  }
}
