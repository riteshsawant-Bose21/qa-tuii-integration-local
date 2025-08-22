
/// Data Transfer Object returned from registration API
class RegistrationResponseDto {
  final String email;
  final int id;

  RegistrationResponseDto({required this.email, required this.id});

  factory RegistrationResponseDto.fromJson(Map<String, dynamic> json) {
    return RegistrationResponseDto(
      email: json['email'] as String,
      id: json['id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'email': email,
      'id': id,
    };
  }
}
