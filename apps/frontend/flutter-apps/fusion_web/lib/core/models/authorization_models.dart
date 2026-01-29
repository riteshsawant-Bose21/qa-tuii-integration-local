import 'package:fusion_web/features/auth/domain/entities/user_entity.dart'
    as auth;

class AuthorizationResponse {
  final UserInfo userInfo;
  final AccountInfo accountInfo;
  final RoleInfo roleInfo;
  final List<String> scopes;

  AuthorizationResponse({
    required this.userInfo,
    required this.accountInfo,
    required this.roleInfo,
    required this.scopes,
  });

  factory AuthorizationResponse.fromJson(Map<String, dynamic> json) {
    return AuthorizationResponse(
      userInfo: UserInfo.fromJson(json['userInfo'] as Map<String, dynamic>),
      accountInfo: AccountInfo.fromJson(
        json['accountInfo'] as Map<String, dynamic>,
      ),
      roleInfo: RoleInfo.fromJson(json['roleInfo'] as Map<String, dynamic>),
      scopes: List<String>.from(json['scopes'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userInfo': userInfo.toJson(),
      'accountInfo': accountInfo.toJson(),
      'roleInfo': roleInfo.toJson(),
      'scopes': scopes,
    };
  }
}

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

// Extension to convert AuthorizationResponse to Auth UserEntity for compatibility
extension AuthorizationResponseExtension on AuthorizationResponse {
  auth.UserEntity toUserEntity() {
    return auth.UserEntity(
      id: userInfo.id,
      name: userInfo.name,
      email: userInfo.email,
      picture: userInfo.avatar,
    );
  }
}
