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
    // Helper function to safely parse DateTime from various formats
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        // Handle the specific "0001-01-01T00:00:00Z" case as null (invalid date)
        if (value.startsWith('0001-01-01')) return null;
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('Failed to parse DateTime: $value');
          return null;
        }
      }
      return null;
    }

    // Helper function to safely get string value
    String getString(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      return value.toString();
    }

    // Helper function to extract role name from role object
    String getRoleName(dynamic roleValue) {
      if (roleValue == null) return 'User';
      if (roleValue is Map<String, dynamic>) {
        return getString(roleValue['role_name'] ?? roleValue['name'], 'User');
      }
      return getString(roleValue, 'User');
    }

    // Helper function to safely get list of strings
    List<String> getStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String) {
        // Handle comma-separated string
        return value
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [];
    }

    return UserModel(
      id: getString(json['id'], ''),
      name: getString(
        json['full_name'] ?? json['name'] ?? json['display_name'],
        'Unknown User',
      ),
      email: getString(json['email'] ?? json['emailAddress'], ''),
      role: getRoleName(json['role']),
      status: getString(json['status'], 'active').toLowerCase() == 'active'
          ? 'Active'
          : 'Inactive',
      createdAt:
          parseDateTime(json['joined_at'] ?? json['created_at']) ??
          DateTime.now(),
      lastLoginAt: parseDateTime(
        json['lastLoginAt'] ?? json['last_login_at'] ?? json['lastLogin'],
      ),
      avatar:
          json['avatar'] as String? ??
          json['profilePicture'] as String? ??
          json['photo'] as String?,
      permissions: getStringList(
        json['permissions'] ?? json['roles'] ?? json['scopes'],
      ),
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
