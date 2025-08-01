/// DTO for user data from API
class UserDto {
  final int id;
  final String email;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  UserDto({
    required this.id,
    required this.email,
    required this.metadata,
    required this.createdAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'],
      email: json['email'],
      // metadata: Map<String, dynamic>.from(json['metadata'] as Map<String, dynamic>),
      metadata: <String, dynamic>{}, // todo: handle metadata properly

      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'metadata': metadata,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
