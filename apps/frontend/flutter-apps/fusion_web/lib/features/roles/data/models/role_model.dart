import 'package:fusion_web/features/roles/domain/entities/role_entity.dart';

// Role Model - Data layer representation
class RoleModel extends RoleEntity {
  const RoleModel({
    required super.id,
    required super.name,
    required super.description,
    required super.permissions,
    required super.createdAt,
    super.updatedAt,
    required super.isSystem,
    required super.userCount,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    print('🔍 [RoleModel] Parsing JSON: $json');

    // Helper function to safely parse DateTime
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        if (value.startsWith('0001-01-01')) return DateTime.now();
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('Failed to parse DateTime: $value');
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    // Helper function to safely parse DateTime that can be null
    DateTime? parseOptionalDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String) {
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

    // Helper function to safely get int value
    int getInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }

    // Helper function to safely get bool value
    bool getBool(dynamic value, bool defaultValue) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) {
        return value.toLowerCase() == 'true';
      }
      return defaultValue;
    }

    try {
      // Extract role information with multiple field name variations
      final String roleId = getString(
        json['id'] ?? json['_id'] ?? json['roleId'] ?? json['role_id'],
        '',
      );
      final String roleName = getString(
        json['name'] ?? json['role_name'] ?? json['roleName'] ?? json['title'],
        'Unknown Role',
      );
      final String roleDesc = getString(
        json['description'] ??
            json['desc'] ??
            json['details'] ??
            json['summary'],
        'No description available',
      );

      // Handle permissions as array or comma-separated string
      List<String> rolePermissions = [];
      final permissionsValue =
          json['permissions'] ?? json['perms'] ?? json['access'];

      if (permissionsValue == null) {
        // Explicitly handle null permissions
        rolePermissions = [];
      } else if (permissionsValue is List) {
        rolePermissions = permissionsValue.map((permission) {
          // Handle complex permission objects from API
          if (permission is Map<String, dynamic>) {
            // Extract feature name from permission object
            final featureName =
                permission['feature_name'] ??
                permission['name'] ??
                permission['permission'] ??
                permission.toString();
            final accessLevel =
                permission['access_level'] ?? permission['level'] ?? '';

            // Combine feature name with access level for better readability
            return accessLevel.isNotEmpty
                ? '$featureName ($accessLevel)'
                : featureName.toString();
          }
          return permission.toString();
        }).toList();
      } else if (permissionsValue is String && permissionsValue.isNotEmpty) {
        rolePermissions = permissionsValue
            .split(',')
            .map((e) => e.trim())
            .toList();
      }

      // Parse user count with various field names
      final int users = getInt(
        json['user_count'] ??
            json['userCount'] ??
            json['users'] ??
            json['assignedUsers'] ??
            json['member_count'] ??
            json['members'],
        0,
      );

      // Determine if system role based on various indicators
      final bool systemRole =
          getBool(
            json['is_system'] ??
                json['isSystem'] ??
                json['system'] ??
                json['built_in'] ??
                json['builtIn'] ??
                json['default'],
            false,
          ) ||
          (roleName.toLowerCase().contains('admin') ||
              roleName.toLowerCase().contains('system'));

      print('✅ [RoleModel] Successfully parsed role: $roleName (ID: $roleId)');

      return RoleModel(
        id: roleId,
        name: roleName,
        description: roleDesc,
        permissions: rolePermissions,
        createdAt: parseDateTime(
          json['created_at'] ?? json['createdAt'] ?? json['dateCreated'],
        ),
        updatedAt: parseOptionalDateTime(
          json['updated_at'] ??
              json['updatedAt'] ??
              json['dateUpdated'] ??
              json['lastModified'],
        ),
        isSystem: systemRole,
        userCount: users,
      );
    } catch (e, stackTrace) {
      print('❌ [RoleModel] Error parsing role from JSON: $e');
      print('📄 [RoleModel] JSON that failed: $json');
      print('📚 [RoleModel] Stack trace: $stackTrace');

      // Return a fallback role with available data
      final fallbackId =
          json['id']?.toString() ??
          json['_id']?.toString() ??
          'unknown_${DateTime.now().millisecondsSinceEpoch}';
      final fallbackName =
          json['name']?.toString() ??
          json['role_name']?.toString() ??
          'Unknown Role';

      return RoleModel(
        id: fallbackId,
        name: fallbackName,
        description: 'Error parsing role data - using fallback',
        permissions: [],
        createdAt: DateTime.now(),
        updatedAt: null,
        isSystem: false,
        userCount: 0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'permissions': permissions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_system': isSystem,
      'user_count': userCount,
    };
  }

  // Helper method to create a copy with updated values
  RoleModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSystem,
    int? userCount,
  }) {
    return RoleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSystem: isSystem ?? this.isSystem,
      userCount: userCount ?? this.userCount,
    );
  }
}
