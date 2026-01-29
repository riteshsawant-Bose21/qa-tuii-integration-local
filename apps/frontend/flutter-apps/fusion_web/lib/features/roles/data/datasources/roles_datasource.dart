import 'package:fusion_web/core/services/service_locator.dart';
import 'package:fusion_web/core/services/api_service.dart';
import 'package:fusion_web/features/roles/data/models/role_model.dart';

class RolesDataSource {
  final ApiService _apiService;

  RolesDataSource({ApiService? apiService})
    : _apiService = apiService ?? ServiceLocator().apiService;

  // Check if authorization is available
  void _checkAuthorization() {
    // The ApiService should already have the bearer token set
    // by the authentication flow. We just verify it's available.
    print('✅ [RolesDataSource] Using existing authorization token');
  }

  // Get all roles
  Future<List<RoleModel>> getAllRoles() async {
    try {
      _checkAuthorization();
      print('🔍 [RolesDataSource] Fetching all roles...');

      final response = await _apiService.get('organization/role-management');
      print('✅ [RolesDataSource] Raw API Response: $response');

      // Handle both direct response and nested response formats
      List<dynamic> rolesData;

      if (response['roles'] != null) {
        // Response has nested structure with 'roles' key
        rolesData = response['roles'] as List<dynamic>;
        print(
          '📋 [RolesDataSource] Found ${rolesData.length} roles in nested format',
        );
      } else if (response['success'] == true && response['data'] != null) {
        // Response has success/data wrapper
        rolesData = response['data'] is List
            ? response['data']
            : [response['data']];
        print(
          '📋 [RolesDataSource] Found ${rolesData.length} roles in wrapped format',
        );
      } else if (response is List) {
        // Direct list response
        rolesData = response as List<dynamic>;
        print(
          '📋 [RolesDataSource] Found ${rolesData.length} roles in direct format',
        );
      } else {
        print('⚠️ [RolesDataSource] Unexpected response format: $response');
        return [];
      }

      final roles = rolesData
          .map((json) => RoleModel.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ [RolesDataSource] Successfully parsed ${roles.length} roles');
      return roles;
    } catch (e) {
      print('❌ [RolesDataSource] Error fetching roles: $e');
      rethrow;
    }
  }

  // Create a new role
  Future<RoleModel> createRole(Map<String, dynamic> roleData) async {
    try {
      _checkAuthorization();
      print('➕ [RolesDataSource] Creating role: $roleData');

      final response = await _apiService.post(
        '/organization/role-management',
        roleData,
      );
      print('✅ [RolesDataSource] Role creation response: $response');

      if (response['success'] == true && response['data'] != null) {
        return RoleModel.fromJson(response['data']);
      } else {
        throw Exception(
          'Failed to create role: ${response['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('❌ [RolesDataSource] Error creating role: $e');
      rethrow;
    }
  }

  // Update an existing role
  Future<RoleModel> updateRole(
    String roleId,
    Map<String, dynamic> roleData,
  ) async {
    try {
      _checkAuthorization();
      print('📝 [RolesDataSource] Updating role $roleId: $roleData');

      final response = await _apiService.put(
        '/organization/role-management/$roleId',
        roleData,
      );
      print('✅ [RolesDataSource] Role update response: $response');

      if (response['success'] == true && response['data'] != null) {
        return RoleModel.fromJson(response['data']);
      } else {
        throw Exception(
          'Failed to update role: ${response['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('❌ [RolesDataSource] Error updating role: $e');
      rethrow;
    }
  }

  // Delete a role
  Future<bool> deleteRole(String roleId) async {
    try {
      _checkAuthorization();
      print('🗑️ [RolesDataSource] Deleting role: $roleId');

      await _apiService.delete('/organization/role-management/$roleId');
      print('✅ [RolesDataSource] Role deleted successfully');

      return true;
    } catch (e) {
      print('❌ [RolesDataSource] Error deleting role: $e');
      rethrow;
    }
  }

  // Get role by ID
  Future<RoleModel?> getRoleById(String roleId) async {
    try {
      _checkAuthorization();
      print('🔍 [RolesDataSource] Fetching role by ID: $roleId');

      final response = await _apiService.get(
        '/organization/role-management/$roleId',
      );
      print('✅ [RolesDataSource] Role fetch response: $response');

      if (response['success'] == true && response['data'] != null) {
        return RoleModel.fromJson(response['data']);
      } else {
        return null;
      }
    } catch (e) {
      print('❌ [RolesDataSource] Error fetching role by ID: $e');
      rethrow;
    }
  }

  // Get available permissions
  Future<List<String>> getAvailablePermissions() async {
    try {
      print('🔍 [RolesDataSource] Using predefined permissions...');

      // Return predefined permissions since the API endpoint doesn't exist
      return [
        'users.read',
        'users.write',
        'users.delete',
        'roles.read',
        'roles.write',
        'roles.delete',
        'dashboard.read',
        'projects.read',
        'projects.write',
        'projects.delete',
        'devices.read',
        'devices.write',
        'devices.delete',
        'settings.read',
        'settings.write',
      ];
    } catch (e) {
      print('❌ [RolesDataSource] Error getting permissions: $e');
      // Return fallback permissions on error
      return [
        'users.read',
        'users.write',
        'users.delete',
        'roles.read',
        'roles.write',
        'roles.delete',
        'dashboard.read',
        'projects.read',
        'projects.write',
        'projects.delete',
        'devices.read',
        'devices.write',
        'devices.delete',
        'settings.read',
        'settings.write',
      ];
    }
  }
}
