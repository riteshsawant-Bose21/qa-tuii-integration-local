import 'package:fusion_web/features/auth/domain/entities/user_entity.dart'
    as auth;

/// Permission level enum for better type safety
enum PermissionLevel {
  none,
  read,
  write;

  static PermissionLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'read':
        return PermissionLevel.read;
      case 'write':
        return PermissionLevel.write;
      default:
        return PermissionLevel.none;
    }
  }

  bool get canRead =>
      this == PermissionLevel.read || this == PermissionLevel.write;
  bool get canWrite => this == PermissionLevel.write;
}

/// Updated authorization response to match actual API structure
class AuthorizationResponse {
  final ApiUserInfo user;
  final ApiAccountInfo account;
  final ApiRoleInfo role;
  final Map<String, String> permissions;

  AuthorizationResponse({
    required this.user,
    required this.account,
    required this.role,
    required this.permissions,
  });

  factory AuthorizationResponse.fromJson(Map<String, dynamic> json) {
    return AuthorizationResponse(
      user: ApiUserInfo.fromJson(json['user'] as Map<String, dynamic>),
      account: ApiAccountInfo.fromJson(json['account'] as Map<String, dynamic>),
      role: ApiRoleInfo.fromJson(json['role'] as Map<String, dynamic>),
      permissions: Map<String, String>.from(
        json['permissions'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'account': account.toJson(),
      'role': role.toJson(),
      'permissions': permissions,
    };
  }
}

/// API User info structure
class ApiUserInfo {
  final String id;
  final String email;

  ApiUserInfo({required this.id, required this.email});

  factory ApiUserInfo.fromJson(Map<String, dynamic> json) {
    return ApiUserInfo(
      id: json['id'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email};
  }
}

/// API Account info structure
class ApiAccountInfo {
  final String id;
  final String name;
  final String description;
  final String type;

  ApiAccountInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
  });

  factory ApiAccountInfo.fromJson(Map<String, dynamic> json) {
    return ApiAccountInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description, 'type': type};
  }
}

/// API Role info structure
class ApiRoleInfo {
  final int id;
  final String roleName;

  ApiRoleInfo({required this.id, required this.roleName});

  factory ApiRoleInfo.fromJson(Map<String, dynamic> json) {
    return ApiRoleInfo(
      id: json['id'] as int,
      roleName: json['role_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'role_name': roleName};
  }
}

/// Extension to convert AuthorizationResponse to Auth UserEntity for compatibility
extension AuthorizationResponseExtension on AuthorizationResponse {
  auth.UserEntity toUserEntity() {
    return auth.UserEntity(
      id: user.id,
      name: user.email.split('@').first, // Extract name from email
      email: user.email,
      picture: null, // No avatar in API response
    );
  }
}

// Keep existing classes for backward compatibility
class UserInfo {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  final String? phone;
  final DateTime? emailVerifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserInfo({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    this.phone,
    this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String?,
      emailVerifiedAt: json['emailVerifiedAt'] != null
          ? DateTime.parse(json['emailVerifiedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'phone': phone,
      'emailVerifiedAt': emailVerifiedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class AccountInfo {
  final String id;
  final String name;
  final String type;
  final String status;
  final DateTime createdAt;
  final Map<String, dynamic>? settings;

  AccountInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.createdAt,
    this.settings,
  });

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      settings: json['settings'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'settings': settings,
    };
  }
}

class RoleInfo {
  final String id;
  final String name;
  final String description;
  final List<String> permissions;
  final int level;

  RoleInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
    required this.level,
  });

  factory RoleInfo.fromJson(Map<String, dynamic> json) {
    return RoleInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      permissions: List<String>.from(json['permissions'] as List),
      level: json['level'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'permissions': permissions,
      'level': level,
    };
  }
}
