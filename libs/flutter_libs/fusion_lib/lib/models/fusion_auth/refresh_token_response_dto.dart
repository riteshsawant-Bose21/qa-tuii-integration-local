/// DTO classes
class RefreshTokenResponseDto {
  final String accessToken;
  final int expiresIn;

  RefreshTokenResponseDto({
    required this.accessToken,
    required this.expiresIn,
  });

  factory RefreshTokenResponseDto.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponseDto(
      accessToken: json['accessToken'] as String,
      expiresIn: json['expiresIn'] as int,
    );
  }

  DateTime get expiryTime {
    return DateTime.now().add(Duration(seconds: expiresIn));
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'accessToken': accessToken,
      'expiresIn': expiresIn,
    };
  }
}
