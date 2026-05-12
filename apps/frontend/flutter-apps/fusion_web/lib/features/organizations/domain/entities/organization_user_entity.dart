import 'package:fusion_web/features/users/domain/entities/user_entity.dart';

// Organization User Entity - Simplified user info for organization contexts
class OrganizationUserEntity {
  final String id;
  final String name;
  final String email;
  final List<String> roles;
  final UserStatus status;
  final UserType userType;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final DateTime? inviteDate;
  final String? avatar;
  final String organizationId;
  final String? phone;
  final bool isActive;

  const OrganizationUserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    required this.status,
    required this.userType,
    required this.createdAt,
    required this.organizationId,
    this.lastLoginAt,
    this.inviteDate,
    this.avatar,
    this.phone,
    this.isActive = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationUserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'OrganizationUserEntity{id: $id, name: $name, email: $email, organizationId: $organizationId}';
  }

  // Helper method to get primary role
  String get primaryRole => roles.isNotEmpty ? roles.first : 'User';

  // Helper method to get joined date formatted string
  String get joinedDisplayDate {
    final date = inviteDate ?? createdAt;
    return '${date.day}/${date.month}/${date.year}';
  }

  // Factory method to create from UserEntity
  factory OrganizationUserEntity.fromUserEntity(
    UserEntity user,
    String organizationId,
  ) {
    return OrganizationUserEntity(
      id: user.id,
      name: user.name,
      email: user.email,
      roles: user.roles,
      status: user.status,
      userType: user.userType,
      createdAt: user.createdAt,
      organizationId: organizationId,
      lastLoginAt: user.lastLoginAt,
      inviteDate: user.inviteDate,
      avatar: user.avatar,
      phone: user.phone,
      isActive: user.isActive,
    );
  }

  // CopyWith method for creating modified copies
  OrganizationUserEntity copyWith({
    String? id,
    String? name,
    String? email,
    List<String>? roles,
    UserStatus? status,
    UserType? userType,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? inviteDate,
    String? avatar,
    String? organizationId,
    String? phone,
    bool? isActive,
  }) {
    return OrganizationUserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      roles: roles ?? this.roles,
      status: status ?? this.status,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      organizationId: organizationId ?? this.organizationId,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      inviteDate: inviteDate ?? this.inviteDate,
      avatar: avatar ?? this.avatar,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
    );
  }
}
