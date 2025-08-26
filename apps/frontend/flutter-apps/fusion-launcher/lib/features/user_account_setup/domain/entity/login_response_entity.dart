import 'package:fusion_launcher/features/user_account_setup/domain/entity/user_entity.dart';
import 'package:fusion_lib/models/fusion_auth/login_response_dto.dart';

/// Entity classes for domain layer
class LoginResponseEntity {
  final String accessToken;
  final String refreshToken;
  final DateTime expiry;
  final UserEntity user;

  LoginResponseEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.expiry,
    required this.user,
  });

  factory LoginResponseEntity.fromDto(LoginResponseDto dto) {
    final DateTime expiryTime = DateTime.now().add(Duration(seconds: dto.expiresIn));
    return LoginResponseEntity(
      accessToken: dto.accessToken,
      refreshToken: dto.refreshToken,
      expiry: expiryTime,
      user: UserEntity.fromDto(dto.user),
    );
  }

  LoginResponseDto toDto() {
    return LoginResponseDto(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiry.difference(DateTime.now()).inSeconds,
      user: user.toDto(),
    );
  }

  factory LoginResponseEntity.fromJson(Map<String, dynamic> json) {
    return LoginResponseEntity(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      expiry: DateTime.parse(json['expiry']),
      user: UserEntity.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expiry': expiry.toIso8601String(),
      'user': user.toJson(),
    };
  }
}
