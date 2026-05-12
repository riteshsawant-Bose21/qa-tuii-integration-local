import 'package:fusion_web/core/models/authorization_models.dart';

/// Service for managing user permissions and role-based access control
/// Updated to work dynamically with API permissions
class PermissionService {
  static PermissionService? _instance;
  AuthorizationResponse? _currentUser;

  PermissionService._internal();

  /// Singleton instance
  static PermissionService get instance {
    _instance ??= PermissionService._internal();
    return _instance!;
  }

  /// Initialize the service with user authorization data from API
  void initialize(AuthorizationResponse authResponse) {
    _currentUser = authResponse;
  }

  /// Clear current user data (e.g., on logout)
  void clear() {
    _currentUser = null;
  }

  /// Get current user's authorization data
  AuthorizationResponse? get currentUser => _currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;

  /// Get current user's role name
  String? get userRole => _currentUser?.role.roleName;

  /// Get current user's role ID
  int? get userRoleId => _currentUser?.role.id;

  /// Get current user's account type
  String? get accountType => _currentUser?.account.type;

  /// Get all user permissions with their levels
  Map<String, String> get userPermissions => _currentUser?.permissions ?? {};

  /// Get all permission keys that user has
  List<String> get availablePermissions => userPermissions.keys.toList();

  /// Check if user has a specific permission (any level)
  bool hasPermission(String permission) {
    if (!isAuthenticated) return false;
    return userPermissions.containsKey(permission);
  }

  /// Check if user has permission with specific level
  bool hasPermissionWithLevel(
    String permission,
    PermissionLevel requiredLevel,
  ) {
    if (!isAuthenticated) return false;

    final userLevel = getPermissionLevel(permission);

    switch (requiredLevel) {
      case PermissionLevel.read:
        return userLevel.canRead;
      case PermissionLevel.write:
        return userLevel.canWrite;
      case PermissionLevel.none:
        return true; // Everyone has "none" level
    }
  }

  /// Get the permission level for a specific permission
  PermissionLevel getPermissionLevel(String permission) {
    if (!isAuthenticated) return PermissionLevel.none;

    final levelString = userPermissions[permission];
    if (levelString == null) return PermissionLevel.none;

    return PermissionLevel.fromString(levelString);
  }

  /// Check if user can read a resource
  bool canRead(String permission) {
    return hasPermissionWithLevel(permission, PermissionLevel.read);
  }

  /// Check if user can write/modify a resource
  bool canWrite(String permission) {
    return hasPermissionWithLevel(permission, PermissionLevel.write);
  }

  /// Check if user has any of the specified permissions
  bool hasAnyPermission(List<String> permissions) {
    return permissions.any((permission) => hasPermission(permission));
  }

  /// Check if user has all of the specified permissions
  bool hasAllPermissions(List<String> permissions) {
    return permissions.every((permission) => hasPermission(permission));
  }

  /// Check if user can read any of the specified permissions
  bool canReadAny(List<String> permissions) {
    return permissions.any((permission) => canRead(permission));
  }

  /// Check if user can write to any of the specified permissions
  bool canWriteAny(List<String> permissions) {
    return permissions.any((permission) => canWrite(permission));
  }

  /// Check if user has a specific role name
  bool hasRole(String role) {
    if (!isAuthenticated) return false;
    return userRole?.toLowerCase() == role.toLowerCase();
  }

  /// Check if user has any of the specified roles
  bool hasAnyRole(List<String> roles) {
    if (!isAuthenticated) return false;
    final currentRole = userRole?.toLowerCase();
    return roles.any((role) => role.toLowerCase() == currentRole);
  }

  /// Check if user is admin (role name contains 'admin')
  bool get isAdmin => userRole?.toLowerCase().contains('admin') ?? false;

  /// Check if user is reseller admin
  bool get isResellerAdmin =>
      isAdmin && accountType?.toLowerCase() == 'reseller';

  /// Check if user is Bose super admin (adjust based on your API structure)
  bool get isBoseSuperAdmin => isAdmin && accountType?.toLowerCase() == 'bose';

  /// Project-specific permission helpers based on API permissions

  // Project permissions
  bool get canViewProjects => canRead('project.read');
  bool get canCreateProjects => canWrite('project.create');
  bool get canUpdateProjects => canWrite('project.update');
  bool get canDeleteProjects => canWrite('project.delete');
  bool get canArchiveProjects => canWrite('project.archive');
  bool get canAssignUsersToProject => canWrite('project.assign_user');
  bool get canManageProjectAccess => canWrite('project.grant_access');

  // Building permissions
  bool get canViewBuildings => canRead('building.view');
  bool get canManageBuildings => canWrite('building.view');
  bool get canUseCostEstimator => canRead('cost_estimator.view');
  bool get canUseCostEstimatorWidget =>
      canWrite('building.cost_estimator_widget');

  // Configuration and commissioning
  bool get canViewConfiguration => canRead('configuration.view');
  bool get canViewCommissioning => canRead('commissioning.view');
  bool get canViewSchematic => canRead('schematic.view');

  /// Get user display information
  Map<String, dynamic> get userDisplayInfo => {
    'id': _currentUser?.user.id ?? '',
    'email': _currentUser?.user.email ?? '',
    'role': _currentUser?.role.roleName ?? 'No Role',
    'roleId': _currentUser?.role.id ?? 0,
    'accountName': _currentUser?.account.name ?? '',
    'accountType': _currentUser?.account.type ?? '',
    'accountDescription': _currentUser?.account.description ?? '',
  };

  /// Get permissions grouped by category
  Map<String, List<String>> get permissionsByCategory {
    final Map<String, List<String>> grouped = {};

    for (final permission in userPermissions.keys) {
      final parts = permission.split('.');
      final category = parts.isNotEmpty ? parts[0] : 'other';

      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(permission);
    }

    return grouped;
  }

  /// Debug method to get all user permissions and roles
  Map<String, dynamic> get debugInfo => {
    'isAuthenticated': isAuthenticated,
    'userRole': userRole,
    'userRoleId': userRoleId,
    'accountType': accountType,
    'permissions': userPermissions,
    'permissionsByCategory': permissionsByCategory,
    'userInfo': userDisplayInfo,
    'isAdmin': isAdmin,
    'isResellerAdmin': isResellerAdmin,
    'isBoseSuperAdmin': isBoseSuperAdmin,
  };
}
