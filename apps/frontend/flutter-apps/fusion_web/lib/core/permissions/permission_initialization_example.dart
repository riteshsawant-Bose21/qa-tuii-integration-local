import 'package:fusion_web/core/models/authorization_models.dart';
import 'package:fusion_web/core/permissions/permissions.dart';

/// Example of how to initialize the permission system with actual API data
class PermissionInitializationExample {
  /// Example: Initialize with the actual API response structure
  static void initializeFromApiResponse() {
    // This would typically be called after successful login/authentication

    // Example API response (as provided by user)
    final Map<String, dynamic> apiResponse = {
      "user": {
        "id": "39cfe695-5f7d-4870-b9da-31f024757a3e",
        "email": "Sujith.Devadas@boseprofessional.com",
      },
      "account": {
        "id": "0c688469-70ba-4104-a51c-c5307c456158",
        "name": "Reseller-Test-Account-1",
        "description": "Test Reseller organization",
        "type": "Reseller",
      },
      "role": {"id": 2, "role_name": "Admin"},
      "permissions": {
        "building.cost_estimator_widget": "write",
        "building.view": "write",
        "commissioning.view": "write",
        "configuration.view": "write",
        "cost_estimator.view": "write",
        "project.archive": "write",
        "project.assign_user": "write",
        "project.create": "write",
        "project.delete": "write",
        "project.grant_access": "write",
        "project.lock": "write",
        "project.read": "write",
        "project.remove_user": "write",
        "project.start": "write",
        "project.unarchive": "write",
        "project.unlock": "write",
        "project.unstar": "write",
        "project.update": "write",
        "schematic.view": "write",
      },
    };

    // Parse the API response
    final authResponse = AuthorizationResponse.fromJson(apiResponse);

    // Initialize the permission service
    PermissionService.instance.initialize(authResponse);

    // Now you can use permissions throughout your app
    print('Permission system initialized!');
    print('User: ${PermissionService.instance.userDisplayInfo['email']}');
    print('Role: ${PermissionService.instance.userRole}');
    print('Account Type: ${PermissionService.instance.accountType}');
    print(
      'Total Permissions: ${PermissionService.instance.availablePermissions.length}',
    );
  }

  /// Example: Check specific permissions after initialization
  static void demonstratePermissionChecks() {
    final service = PermissionService.instance;

    print('\n=== Permission Check Examples ===');

    // Basic permission checks
    print('Can read projects: ${service.canRead('project.read')}');
    print('Can create projects: ${service.canWrite('project.create')}');
    print('Can view buildings: ${service.hasPermission('building.view')}');

    // Role checks
    print('Is Admin: ${service.isAdmin}');
    print('Is Reseller Admin: ${service.isResellerAdmin}');

    // Permission level checks
    print(
      'Project read permission level: ${service.getPermissionLevel('project.read')}',
    );
    print(
      'Building view permission level: ${service.getPermissionLevel('building.view')}',
    );

    // Grouped permissions
    final permissionsByCategory = service.permissionsByCategory;
    print('\nPermissions by category:');
    permissionsByCategory.forEach((category, perms) {
      print('  $category: ${perms.length} permissions');
    });

    // Debug info
    print('\nDebug Info:');
    print(service.debugInfo);
  }

  /// Example: Usage in authentication flow
  static Future<bool> handleLogin(String email, String password) async {
    try {
      // 1. Authenticate with your backend
      // final loginResponse = await authService.login(email, password);

      // 2. Fetch authorization data from /users/authorization endpoint
      // final authResponse = await authService.getAuthorization();

      // For demo, using the provided example
      final Map<String, dynamic> authData = {
        "user": {"id": "39cfe695-5f7d-4870-b9da-31f024757a3e", "email": email},
        "account": {
          "id": "0c688469-70ba-4104-a51c-c5307c456158",
          "name": "Reseller-Test-Account-1",
          "description": "Test Reseller organization",
          "type": "Reseller",
        },
        "role": {"id": 2, "role_name": "Admin"},
        "permissions": {
          "building.cost_estimator_widget": "write",
          "building.view": "write",
          "commissioning.view": "write",
          "configuration.view": "write",
          "cost_estimator.view": "write",
          "project.archive": "write",
          "project.assign_user": "write",
          "project.create": "write",
          "project.delete": "write",
          "project.grant_access": "write",
          "project.lock": "write",
          "project.read": "write",
          "project.remove_user": "write",
          "project.start": "write",
          "project.unarchive": "write",
          "project.unlock": "write",
          "project.unstar": "write",
          "project.update": "write",
          "schematic.view": "write",
        },
      };

      // 3. Parse and initialize permissions
      final authResponse = AuthorizationResponse.fromJson(authData);
      PermissionService.instance.initialize(authResponse);

      return true;
    } catch (e) {
      print('Login failed: $e');
      return false;
    }
  }

  /// Example: Clear permissions on logout
  static void handleLogout() {
    PermissionService.instance.clear();
    print('Permissions cleared on logout');
  }
}
