// User Status Enum
enum UserStatus {
  active,
  invited,
  pending,
  inactive;

  String get displayName {
    switch (this) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.invited:
        return 'Invited';
      case UserStatus.pending:
        return 'Pending';
      case UserStatus.inactive:
        return 'Inactive';
    }
  }

  static UserStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return UserStatus.active;
      case 'invited':
        return UserStatus.invited;
      case 'pending':
        return UserStatus.pending;
      case 'inactive':
        return UserStatus.inactive;
      default:
        return UserStatus.pending;
    }
  }
}

// User Type Enum
enum UserType {
  admin,
  contributor,
  viewer,
  designer,
  technician;

  String get displayName {
    switch (this) {
      case UserType.admin:
        return 'Admin';
      case UserType.contributor:
        return 'Contributor';
      case UserType.viewer:
        return 'Viewer';
      case UserType.designer:
        return 'Designer';
      case UserType.technician:
        return 'Technician';
    }
  }

  static UserType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'admin':
        return UserType.admin;
      case 'contributor':
        return UserType.contributor;
      case 'viewer':
        return UserType.viewer;
      case 'designer':
        return UserType.designer;
      case 'technician':
        return UserType.technician;
      default:
        return UserType.viewer;
    }
  }
}

// User Entity - Core business object
class UserEntity {
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
  final List<String> permissions;
  final List<String> associatedProjects;
  final String? organizationId;
  final String? phone;
  final Map<String, dynamic>? activityHistory;
  final bool isActive;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    required this.status,
    required this.userType,
    required this.createdAt,
    this.lastLoginAt,
    this.inviteDate,
    this.avatar,
    required this.permissions,
    this.associatedProjects = const [],
    this.organizationId,
    this.phone,
    this.activityHistory,
    this.isActive = true,
  });

  // Helper getter for backward compatibility
  String get role => roles.isNotEmpty ? roles.first : 'User';

  UserEntity copyWith({
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
    List<String>? permissions,
    List<String>? associatedProjects,
    String? organizationId,
    String? phone,
    Map<String, dynamic>? activityHistory,
    bool? isActive,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      roles: roles ?? this.roles,
      status: status ?? this.status,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      inviteDate: inviteDate ?? this.inviteDate,
      avatar: avatar ?? this.avatar,
      permissions: permissions ?? this.permissions,
      associatedProjects: associatedProjects ?? this.associatedProjects,
      organizationId: organizationId ?? this.organizationId,
      phone: phone ?? this.phone,
      activityHistory: activityHistory ?? this.activityHistory,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}
