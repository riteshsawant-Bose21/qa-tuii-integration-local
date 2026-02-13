import 'package:fusion_web/features/users/domain/entities/user_entity.dart';

// User Model - Data layer representation
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.roles,
    required super.status,
    required super.userType,
    required super.createdAt,
    super.lastLoginAt,
    super.inviteDate,
    super.avatar,
    required super.permissions,
    super.associatedProjects = const [],
    super.organizationId,
    super.phone,
    super.activityHistory,
    super.isActive = true,
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

    // Helper function to extract role names from role object
    List<String> getRolesList(dynamic roleValue) {
      if (roleValue == null) return ['User'];
      if (roleValue is List) {
        return roleValue.map((e) {
          if (e is Map<String, dynamic>) {
            return getString(e['role_name'] ?? e['name'], 'User');
          }
          return e.toString();
        }).toList();
      }
      if (roleValue is Map<String, dynamic>) {
        return [getString(roleValue['role_name'] ?? roleValue['name'], 'User')];
      }
      if (roleValue is String) {
        return [roleValue];
      }
      return ['User'];
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

    // Helper function to get activity history
    Map<String, dynamic>? getActivityHistory(dynamic value) {
      if (value == null) return null;
      if (value is Map<String, dynamic>) return value;
      return null;
    }

    final statusStr = getString(json['status'], 'pending');
    final userTypeStr = getString(json['user_type'] ?? json['type'], 'viewer');
    final isActiveValue = json['is_active'] ?? json['isActive'] ?? 
                          (statusStr.toLowerCase() == 'active');

    return UserModel(
      id: getString(json['id'], ''),
      name: getString(
        json['full_name'] ?? json['name'] ?? json['display_name'],
        'Unknown User',
      ),
      email: getString(json['email'] ?? json['emailAddress'], ''),
      roles: getRolesList(json['roles'] ?? json['role']),
      status: UserStatus.fromString(statusStr),
      userType: UserType.fromString(userTypeStr),
      createdAt:
          parseDateTime(json['joined_at'] ?? json['created_at']) ??
          DateTime.now(),
      lastLoginAt: parseDateTime(
        json['lastLoginAt'] ?? json['last_login_at'] ?? json['lastLogin'],
      ),
      inviteDate: parseDateTime(
        json['invite_date'] ?? json['invited_at'] ?? json['inviteDate'],
      ),
      avatar:
          json['avatar'] as String? ??
          json['profilePicture'] as String? ??
          json['photo'] as String?,
      permissions: getStringList(
        json['permissions'] ?? json['scopes'],
      ),
      associatedProjects: getStringList(
        json['associated_projects'] ?? json['projects'] ?? json['project_ids'],
      ),
      organizationId: json['organization_id'] as String? ?? 
                      json['org_id'] as String?,
      phone: json['phone'] as String? ?? json['phone_number'] as String?,
      activityHistory: getActivityHistory(json['activity_history']),
      isActive: isActiveValue is bool ? isActiveValue : 
                (isActiveValue.toString().toLowerCase() == 'true'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'roles': roles,
      'status': status.displayName,
      'user_type': userType.displayName,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'invite_date': inviteDate?.toIso8601String(),
      'avatar': avatar,
      'permissions': permissions,
      'associated_projects': associatedProjects,
      'organization_id': organizationId,
      'phone': phone,
      'activity_history': activityHistory,
      'is_active': isActive,
    };
  }

  static List<UserModel> mockUsers() {
    return [
      UserModel(
        id: '1',
        name: 'John Doe',
        email: 'john.doe@example.com',
        roles: ['Admin', 'Project Manager'],
        status: UserStatus.active,
        userType: UserType.admin,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)),
        permissions: ['read', 'write', 'delete', 'admin'],
        associatedProjects: ['project-1', 'project-2', 'project-3'],
        organizationId: 'org-1',
        phone: '+1-555-0101',
        isActive: true,
      ),
      UserModel(
        id: '2',
        name: 'Jane Smith',
        email: 'jane.smith@example.com',
        roles: ['Developer', 'Contributor'],
        status: UserStatus.active,
        userType: UserType.contributor,
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        lastLoginAt: DateTime.now().subtract(const Duration(days: 1)),
        permissions: ['read', 'write'],
        associatedProjects: ['project-1', 'project-4'],
        organizationId: 'org-1',
        phone: '+1-555-0102',
        isActive: true,
      ),
      UserModel(
        id: '3',
        name: 'Mike Johnson',
        email: 'mike.johnson@example.com',
        roles: ['Designer'],
        status: UserStatus.active,
        userType: UserType.designer,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 5)),
        permissions: ['read', 'write'],
        associatedProjects: ['project-2', 'project-5'],
        organizationId: 'org-1',
        phone: '+1-555-0103',
        isActive: true,
      ),
      UserModel(
        id: '4',
        name: 'Sarah Wilson',
        email: 'sarah.wilson@example.com',
        roles: ['Technician'],
        status: UserStatus.inactive,
        userType: UserType.technician,
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
        lastLoginAt: DateTime.now().subtract(const Duration(days: 30)),
        permissions: ['read', 'write', 'manage'],
        associatedProjects: ['project-3'],
        organizationId: 'org-1',
        isActive: false,
      ),
      UserModel(
        id: '5',
        name: 'David Brown',
        email: 'david.brown@example.com',
        roles: ['Viewer'],
        status: UserStatus.invited,
        userType: UserType.viewer,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        inviteDate: DateTime.now().subtract(const Duration(days: 7)),
        permissions: ['read'],
        associatedProjects: ['project-1'],
        organizationId: 'org-1',
        isActive: false,
      ),
      UserModel(
        id: '6',
        name: 'Emily Davis',
        email: 'emily.davis@example.com',
        roles: ['Contributor'],
        status: UserStatus.pending,
        userType: UserType.contributor,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        inviteDate: DateTime.now().subtract(const Duration(days: 2)),
        permissions: ['read', 'write'],
        associatedProjects: [],
        organizationId: 'org-1',
        isActive: false,
      ),
    ];
  }
}
