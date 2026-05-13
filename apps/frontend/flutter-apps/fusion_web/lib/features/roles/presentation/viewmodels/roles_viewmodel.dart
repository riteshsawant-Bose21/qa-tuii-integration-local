import 'package:flutter/material.dart';
import 'package:fusion_web/features/roles/domain/entities/role_entity.dart';
import 'package:fusion_web/features/roles/domain/usecases/roles_usecases.dart';

enum RolesViewState { initial, loading, loaded, error, empty }

class RolesViewModel extends ChangeNotifier {
  final RolesUseCases _useCases;

  RolesViewModel(this._useCases);

  // State management
  RolesViewState _state = RolesViewState.initial;
  List<RoleEntity> _roles = [];
  List<String> _availablePermissions = [];
  String _errorMessage = '';
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;

  // Getters
  RolesViewState get state => _state;
  List<RoleEntity> get roles => _roles;
  List<String> get availablePermissions => _availablePermissions;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  // Get filtered and sorted roles
  List<RoleEntity> get filteredRoles {
    final filtered = _useCases.filterRoles(_roles, _searchQuery);
    return _useCases.sortRoles(filtered, _sortBy, _sortAscending);
  }

  // Load all roles
  Future<void> loadRoles() async {
    _setState(RolesViewState.loading);

    try {
      final roles = await _useCases.getAllRoles();
      _roles = roles;

      if (roles.isEmpty) {
        _setState(RolesViewState.empty);
      } else {
        _setState(RolesViewState.loaded);
      }
    } catch (e) {
      _errorMessage = 'Failed to load roles: ${e.toString()}';
      _setState(RolesViewState.error);
    }
  }

  // Load available permissions
  Future<void> loadAvailablePermissions() async {
    try {
      _availablePermissions = await _useCases.getAvailablePermissions();
      notifyListeners();
    } catch (e) {
      print('Failed to load permissions: $e');
    }
  }

  // Create a new role
  Future<bool> createRole({
    required String name,
    required String description,
    required List<String> permissions,
  }) async {
    try {
      // Validate input
      final errors = _useCases.validateRoleData(
        name: name,
        description: description,
        permissions: permissions,
      );

      if (errors.isNotEmpty) {
        _errorMessage = errors.values.first;
        return false;
      }

      final newRole = await _useCases.createRole(
        name: name,
        description: description,
        permissions: permissions,
      );

      _roles.add(newRole);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create role: ${e.toString()}';
      return false;
    }
  }

  // Update an existing role
  Future<bool> updateRole({
    required String roleId,
    required String name,
    required String description,
    required List<String> permissions,
  }) async {
    try {
      // Validate input
      final errors = _useCases.validateRoleData(
        name: name,
        description: description,
        permissions: permissions,
      );

      if (errors.isNotEmpty) {
        _errorMessage = errors.values.first;
        return false;
      }

      final updatedRole = await _useCases.updateRole(
        roleId: roleId,
        name: name,
        description: description,
        permissions: permissions,
      );

      final index = _roles.indexWhere((role) => role.id == roleId);
      if (index != -1) {
        _roles[index] = updatedRole;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update role: ${e.toString()}';
      return false;
    }
  }

  // Delete a role
  Future<bool> deleteRole(String roleId) async {
    try {
      final success = await _useCases.deleteRole(roleId);

      if (success) {
        _roles.removeWhere((role) => role.id == roleId);

        if (_roles.isEmpty) {
          _setState(RolesViewState.empty);
        } else {
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to delete role: ${e.toString()}';
      return false;
    }
  }

  // Search roles
  void searchRoles(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Sort roles
  void sortRoles(String sortBy, bool ascending) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Refresh roles
  Future<void> refreshRoles() async {
    await loadRoles();
  }

  // Private helper method to set state
  void _setState(RolesViewState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
