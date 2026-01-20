import 'package:fusion_web/features/users/domain/entities/user_entity.dart';

// User Model - Data layer representation
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    required super.status,
    required super.createdAt,
    super.lastLoginAt,
    super.avatar,
    required super.permissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      avatar: json['avatar'] as String?,
      permissions: List<String>.from(json['permissions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'avatar': avatar,
      'permissions': permissions,
    };
  }

  static List<UserModel> mockUsers() {
    return [
      UserModel(
        id: '1',
        name: 'John Doe',
        email: 'john.doe@example.com',
        role: 'Admin',
        status: 'Active',
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)),
        permissions: ['read', 'write', 'delete', 'admin'],
      ),
      UserModel(
        id: '2',
        name: 'Jane Smith',
        email: 'jane.smith@example.com',
        role: 'Developer',
        status: 'Active',
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        lastLoginAt: DateTime.now().subtract(const Duration(days: 1)),
        permissions: ['read', 'write'],
      ),
      UserModel(
        id: '3',
        name: 'Mike Johnson',
        email: 'mike.johnson@example.com',
        role: 'Designer',
        status: 'Active',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 5)),
        permissions: ['read', 'write'],
      ),
      UserModel(
        id: '4',
        name: 'Sarah Wilson',
        email: 'sarah.wilson@example.com',
        role: 'Manager',
        status: 'Inactive',
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
        lastLoginAt: DateTime.now().subtract(const Duration(days: 30)),
        permissions: ['read', 'write', 'manage'],
      ),
    ];
  }
}
