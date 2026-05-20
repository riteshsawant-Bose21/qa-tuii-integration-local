import 'package:flutter/material.dart';
import 'package:fusion_web/core/permissions/permission_service.dart';
import 'package:fusion_web/core/models/authorization_models.dart';

/// Extension methods for BuildContext to easily check permissions
extension PermissionExtension on BuildContext {
  PermissionService get permissions => PermissionService.instance;

  /// Check if user has a specific permission
  bool hasPermission(String permission) =>
      permissions.hasPermission(permission);

  /// Check if user has permission with specific level
  bool hasPermissionWithLevel(String permission, PermissionLevel level) =>
      permissions.hasPermissionWithLevel(permission, level);

  /// Check if user can read a resource
  bool canRead(String permission) => permissions.canRead(permission);

  /// Check if user can write/modify a resource
  bool canWrite(String permission) => permissions.canWrite(permission);

  /// Check if user has any of the specified permissions
  bool hasAnyPermission(List<String> perms) =>
      permissions.hasAnyPermission(perms);

  /// Check if user has all of the specified permissions
  bool hasAllPermissions(List<String> perms) =>
      permissions.hasAllPermissions(perms);

  /// Check if user has a specific role
  bool hasRole(String role) => permissions.hasRole(role);

  /// Check if user has any of the specified roles
  bool hasAnyRole(List<String> roles) => permissions.hasAnyRole(roles);

  /// Check if user is authenticated
  bool get isAuthenticated => permissions.isAuthenticated;

  /// Check if user is reseller admin
  bool get isResellerAdmin => permissions.isResellerAdmin;

  /// Check if user is Bose super admin
  bool get isBoseSuperAdmin => permissions.isBoseSuperAdmin;

  /// Check if user is any type of admin
  bool get isAdmin => permissions.isAdmin;

  /// Get current user role
  String? get userRole => permissions.userRole;

  /// Get user display information
  Map<String, dynamic> get userDisplayInfo => permissions.userDisplayInfo;

  // Project-specific convenience methods
  bool get canViewProjects => permissions.canViewProjects;
  bool get canCreateProjects => permissions.canCreateProjects;
  bool get canUpdateProjects => permissions.canUpdateProjects;
  bool get canDeleteProjects => permissions.canDeleteProjects;
  bool get canViewBuildings => permissions.canViewBuildings;
  bool get canUseCostEstimator => permissions.canUseCostEstimator;
}

/// Extension for Widget to add permission-based conditional rendering
extension WidgetPermissionExtension on Widget {
  /// Show this widget only if condition is true
  Widget showIf(bool condition) {
    return condition ? this : const SizedBox.shrink();
  }

  /// Show this widget only if user has the specified permission
  Widget showIfPermission(String permission) {
    return showIf(PermissionService.instance.hasPermission(permission));
  }

  /// Show this widget only if user has permission with specific level
  Widget showIfPermissionWithLevel(String permission, PermissionLevel level) {
    return showIf(
      PermissionService.instance.hasPermissionWithLevel(permission, level),
    );
  }

  /// Show this widget only if user can read the permission
  Widget showIfCanRead(String permission) {
    return showIf(PermissionService.instance.canRead(permission));
  }

  /// Show this widget only if user can write to the permission
  Widget showIfCanWrite(String permission) {
    return showIf(PermissionService.instance.canWrite(permission));
  }

  /// Show this widget only if user has any of the specified permissions
  Widget showIfAnyPermission(List<String> permissions) {
    return showIf(PermissionService.instance.hasAnyPermission(permissions));
  }

  /// Show this widget only if user has all of the specified permissions
  Widget showIfAllPermissions(List<String> permissions) {
    return showIf(PermissionService.instance.hasAllPermissions(permissions));
  }

  /// Show this widget only if user has the specified role
  Widget showIfRole(String role) {
    return showIf(PermissionService.instance.hasRole(role));
  }

  /// Show this widget only if user has any of the specified roles
  Widget showIfAnyRole(List<String> roles) {
    return showIf(PermissionService.instance.hasAnyRole(roles));
  }

  /// Show this widget only if user is admin
  Widget showIfAdmin() {
    return showIf(PermissionService.instance.isAdmin);
  }

  /// Show this widget only if user is reseller admin
  Widget showIfResellerAdmin() {
    return showIf(PermissionService.instance.isResellerAdmin);
  }

  /// Show this widget only if user is Bose super admin
  Widget showIfBoseSuperAdmin() {
    return showIf(PermissionService.instance.isBoseSuperAdmin);
  }
}

/// Extension for List<Widget> to filter based on permissions
extension WidgetListPermissionExtension on List<Widget> {
  /// Filter widgets based on permission check
  List<Widget> filterByPermissions() {
    return this; // All widgets in the list are already Widget type
  }
}

/// Extension for Route/Navigation
extension NavigationPermissionExtension on NavigatorState {
  /// Push named route with permission check
  Future<T?> pushNamedWithPermission<T extends Object?>(
    String routeName, {
    required String permission,
    Object? arguments,
    VoidCallback? onAccessDenied,
    PermissionLevel? requiredLevel,
  }) {
    bool hasAccess = requiredLevel != null
        ? PermissionService.instance.hasPermissionWithLevel(
            permission,
            requiredLevel,
          )
        : PermissionService.instance.hasPermission(permission);

    if (hasAccess) {
      return pushNamed<T>(routeName, arguments: arguments);
    } else {
      onAccessDenied?.call();
      return Future.value(null);
    }
  }

  /// Push replacement named route with permission check
  Future<T?>
  pushReplacementNamedWithPermission<T extends Object?, TO extends Object?>(
    String routeName, {
    required String permission,
    Object? arguments,
    TO? result,
    VoidCallback? onAccessDenied,
    PermissionLevel? requiredLevel,
  }) {
    bool hasAccess = requiredLevel != null
        ? PermissionService.instance.hasPermissionWithLevel(
            permission,
            requiredLevel,
          )
        : PermissionService.instance.hasPermission(permission);

    if (hasAccess) {
      return pushReplacementNamed<T, TO>(
        routeName,
        arguments: arguments,
        result: result,
      );
    } else {
      onAccessDenied?.call();
      return Future.value(null);
    }
  }
}

/// String extension for permission constants
extension PermissionStringExtension on String {
  /// Check if current user has this permission
  bool get isGranted => PermissionService.instance.hasPermission(this);

  /// Check if current user can read this permission
  bool get canRead => PermissionService.instance.canRead(this);

  /// Check if current user can write to this permission
  bool get canWrite => PermissionService.instance.canWrite(this);

  /// Check if this role matches current user's role
  bool get isUserRole => PermissionService.instance.hasRole(this);

  /// Get the permission level for this permission
  PermissionLevel get permissionLevel =>
      PermissionService.instance.getPermissionLevel(this);
}
