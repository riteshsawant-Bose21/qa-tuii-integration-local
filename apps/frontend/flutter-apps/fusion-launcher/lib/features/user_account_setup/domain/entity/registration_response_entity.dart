import 'package:fusion_lib/models/fusion_auth/registration_response_dto.dart';

/// Domain entity for registration response
class RegistrationResponseEntity {
  final String email;
  final int id;

  RegistrationResponseEntity({required this.email, required this.id});

  /// Convert DTO to entity
  factory RegistrationResponseEntity.fromDto(RegistrationResponseDto dto) {
    return RegistrationResponseEntity(
      email: dto.email,
      id: dto.id,
    );
  }

  /// Convert entity back to DTO
  RegistrationResponseDto toDto() {
    return RegistrationResponseDto(
      email: email,
      id: id,
    );
  }
}
