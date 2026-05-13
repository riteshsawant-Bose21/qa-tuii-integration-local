import 'package:flutter/material.dart';
import 'package:fusion_web/core/permissions/permission_service.dart';
import 'package:fusion_web/core/models/authorization_models.dart';

/// Widget that conditionally shows its child based on user permissions
class PermissionGate extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  final List<String>? permissions;
  final List<String>? roles;
  final String? permission;
  final String? role;
  final bool requireAll;
  final PermissionLevel? requiredLevel;

  const PermissionGate({
    super.key,
    required this.child,
    this.fallback,
    this.permissions,
    this.roles,
    this.permission,
    this.role,
    this.requireAll = false,
    this.requiredLevel,
  }) : assert(
         permissions != null ||
             roles != null ||
             permission != null ||
             role != null,
         'At least one permission check parameter must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService.instance;

    if (!permissionService.isAuthenticated) {
      return fallback ?? const SizedBox.shrink();
    }

    bool hasAccess = true;

    // Check single permission
    if (permission != null) {
      if (requiredLevel != null) {
        hasAccess =
            hasAccess &&
            permissionService.hasPermissionWithLevel(
              permission!,
              requiredLevel!,
            );
      } else {
        hasAccess = hasAccess && permissionService.hasPermission(permission!);
      }
    }

    // Check single role
    if (role != null) {
      hasAccess = hasAccess && permissionService.hasRole(role!);
    }

    // Check multiple permissions
    if (permissions != null && permissions!.isNotEmpty) {
      if (requireAll) {
        hasAccess =
            hasAccess && permissionService.hasAllPermissions(permissions!);
      } else {
        hasAccess =
            hasAccess && permissionService.hasAnyPermission(permissions!);
      }
    }

    // Check multiple roles
    if (roles != null && roles!.isNotEmpty) {
      hasAccess = hasAccess && permissionService.hasAnyRole(roles!);
    }

    return hasAccess ? child : (fallback ?? const SizedBox.shrink());
  }
}

/// Widget that shows different content based on user role
class RoleBasedWidget extends StatelessWidget {
  final Map<String, Widget> roleWidgets;
  final Widget? defaultWidget;

  const RoleBasedWidget({
    super.key,
    required this.roleWidgets,
    this.defaultWidget,
  });

  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService.instance;
    final userRole = permissionService.userRole?.toLowerCase();

    if (userRole != null) {
      // Try exact match first
      for (final entry in roleWidgets.entries) {
        if (entry.key.toLowerCase() == userRole) {
          return entry.value;
        }
      }

      // Try partial match (for cases like 'Admin' role matching 'admin' key)
      for (final entry in roleWidgets.entries) {
        if (userRole.contains(entry.key.toLowerCase()) ||
            entry.key.toLowerCase().contains(userRole)) {
          return entry.value;
        }
      }
    }

    return defaultWidget ?? const SizedBox.shrink();
  }
}

/// Widget for conditional navigation items
class PermissionNavigationItem extends StatelessWidget {
  final Widget child;
  final String? permission;
  final List<String>? permissions;
  final String? role;
  final List<String>? roles;
  final bool requireAll;
  final PermissionLevel? requiredLevel;

  const PermissionNavigationItem({
    super.key,
    required this.child,
    this.permission,
    this.permissions,
    this.role,
    this.roles,
    this.requireAll = false,
    this.requiredLevel,
  });

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permission: permission,
      permissions: permissions,
      role: role,
      roles: roles,
      requireAll: requireAll,
      requiredLevel: requiredLevel,
      child: child,
    );
  }
}

/// Mixin for widgets that need permission checking
mixin PermissionMixin {
  PermissionService get permissionService => PermissionService.instance;

  bool hasPermission(String permission) =>
      permissionService.hasPermission(permission);

  bool hasPermissionWithLevel(String permission, PermissionLevel level) =>
      permissionService.hasPermissionWithLevel(permission, level);

  bool canRead(String permission) => permissionService.canRead(permission);

  bool canWrite(String permission) => permissionService.canWrite(permission);

  bool hasAnyPermission(List<String> permissions) =>
      permissionService.hasAnyPermission(permissions);

  bool hasAllPermissions(List<String> permissions) =>
      permissionService.hasAllPermissions(permissions);

  bool hasRole(String role) => permissionService.hasRole(role);

  bool hasAnyRole(List<String> roles) => permissionService.hasAnyRole(roles);

  bool get isResellerAdmin => permissionService.isResellerAdmin;

  bool get isBoseSuperAdmin => permissionService.isBoseSuperAdmin;

  bool get isAdmin => permissionService.isAdmin;

  // Project-specific convenience methods
  bool get canViewProjects => permissionService.canViewProjects;
  bool get canCreateProjects => permissionService.canCreateProjects;
  bool get canUpdateProjects => permissionService.canUpdateProjects;
  bool get canDeleteProjects => permissionService.canDeleteProjects;
  bool get canViewBuildings => permissionService.canViewBuildings;
  bool get canUseCostEstimator => permissionService.canUseCostEstimator;

  /// Show conditional dialog based on permissions
  void showPermissionDialog(
    BuildContext context, {
    required String permission,
    required Widget Function(BuildContext) builder,
    Widget Function(BuildContext)? fallbackBuilder,
    PermissionLevel? requiredLevel,
  }) {
    bool hasAccess = requiredLevel != null
        ? hasPermissionWithLevel(permission, requiredLevel)
        : hasPermission(permission);

    if (hasAccess) {
      showDialog(context: context, builder: builder);
    } else if (fallbackBuilder != null) {
      showDialog(context: context, builder: fallbackBuilder);
    }
  }

  /// Navigate conditionally based on permissions
  void navigateWithPermission(
    BuildContext context, {
    required String permission,
    required String route,
    Object? arguments,
    VoidCallback? onAccessDenied,
    PermissionLevel? requiredLevel,
  }) {
    bool hasAccess = requiredLevel != null
        ? hasPermissionWithLevel(permission, requiredLevel)
        : hasPermission(permission);

    if (hasAccess) {
      Navigator.pushNamed(context, route, arguments: arguments);
    } else {
      onAccessDenied?.call();
    }
  }
}
