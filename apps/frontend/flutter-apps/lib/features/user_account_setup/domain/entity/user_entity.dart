import '../../data/models/user_dto.dart';

/// Domain entity representing a user
class UserEntity {
  final int id;
  final String email;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  UserEntity({
    required this.id,
    required this.email,
    required this.metadata,
    required this.createdAt,
  });

  /// Convert DTO to entity
  factory UserEntity.fromDto(UserDto dto) {
    return UserEntity(
      id: dto.id,
      email: dto.email,
      metadata: dto.metadata,
      createdAt: dto.createdAt,
    );
  }

  /// Convert entity back to DTO
  UserDto toDto() {
    return UserDto(
      id: id,
      email: email,
      metadata: metadata,
      createdAt: createdAt,
    );
  }

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'],
      email: json['email'],
      metadata: Map<String, dynamic>.from(json['metadata'] as Map<String, dynamic>),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'metadata': metadata,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
