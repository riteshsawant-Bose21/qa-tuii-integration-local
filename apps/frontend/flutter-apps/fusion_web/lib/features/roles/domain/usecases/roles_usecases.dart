import 'package:fusion_web/features/roles/domain/entities/role_entity.dart';
import 'package:fusion_web/features/roles/domain/repositories/roles_repository.dart';

class RolesUseCases {
  final RolesRepository _repository;

  RolesUseCases(this._repository);

  // Get all roles
  Future<List<RoleEntity>> getAllRoles() async {
    return await _repository.getAllRoles();
  }

  // Create a new role
  Future<RoleEntity> createRole({
    required String name,
    required String description,
    required List<String> permissions,
  }) async {
    final roleData = {
      'name': name,
      'description': description,
      'permissions': permissions,
      'is_system': false,
    };
    return await _repository.createRole(roleData);
  }

  // Update an existing role
  Future<RoleEntity> updateRole({
    required String roleId,
    required String name,
    required String description,
    required List<String> permissions,
  }) async {
    final roleData = {
      'name': name,
      'description': description,
      'permissions': permissions,
    };
    return await _repository.updateRole(roleId, roleData);
  }

  // Delete a role
  Future<bool> deleteRole(String roleId) async {
    return await _repository.deleteRole(roleId);
  }

  // Get role by ID
  Future<RoleEntity?> getRoleById(String roleId) async {
    return await _repository.getRoleById(roleId);
  }

  // Get available permissions
  Future<List<String>> getAvailablePermissions() async {
    return await _repository.getAvailablePermissions();
  }

  // Search and filter roles
  List<RoleEntity> filterRoles(List<RoleEntity> roles, String searchQuery) {
    if (searchQuery.isEmpty) return roles;

    return roles.where((role) {
      final query = searchQuery.toLowerCase();
      return role.name.toLowerCase().contains(query) ||
          role.description.toLowerCase().contains(query) ||
          role.permissions.any(
            (permission) => permission.toLowerCase().contains(query),
          );
    }).toList();
  }

  // Sort roles by different criteria
  List<RoleEntity> sortRoles(
    List<RoleEntity> roles,
    String sortBy,
    bool ascending,
  ) {
    final sortedRoles = List<RoleEntity>.from(roles);

    switch (sortBy.toLowerCase()) {
      case 'name':
        sortedRoles.sort(
          (a, b) =>
              ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name),
        );
        break;
      case 'users':
        sortedRoles.sort(
          (a, b) => ascending
              ? a.userCount.compareTo(b.userCount)
              : b.userCount.compareTo(a.userCount),
        );
        break;
      case 'permissions':
        sortedRoles.sort(
          (a, b) => ascending
              ? a.permissions.length.compareTo(b.permissions.length)
              : b.permissions.length.compareTo(a.permissions.length),
        );
        break;
      case 'created':
        sortedRoles.sort(
          (a, b) => ascending
              ? a.createdAt.compareTo(b.createdAt)
              : b.createdAt.compareTo(a.createdAt),
        );
        break;
      default:
        // Default sort by name
        sortedRoles.sort(
          (a, b) =>
              ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name),
        );
    }

    return sortedRoles;
  }

  // Validate role data
  Map<String, String> validateRoleData({
    required String name,
    required String description,
    required List<String> permissions,
  }) {
    final errors = <String, String>{};

    if (name.trim().isEmpty) {
      errors['name'] = 'Role name is required';
    } else if (name.trim().length < 2) {
      errors['name'] = 'Role name must be at least 2 characters';
    }

    if (description.trim().isEmpty) {
      errors['description'] = 'Role description is required';
    } else if (description.trim().length < 5) {
      errors['description'] = 'Role description must be at least 5 characters';
    }

    if (permissions.isEmpty) {
      errors['permissions'] = 'At least one permission is required';
    }

    return errors;
  }
}
