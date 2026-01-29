import 'package:fusion_web/features/roles/domain/entities/role_entity.dart';
import 'package:fusion_web/features/roles/domain/repositories/roles_repository.dart';
import 'package:fusion_web/features/roles/data/datasources/roles_datasource.dart';

class RolesRepositoryImpl implements RolesRepository {
  final RolesDataSource _dataSource;

  RolesRepositoryImpl(this._dataSource);

  @override
  Future<List<RoleEntity>> getAllRoles() async {
    try {
      final roles = await _dataSource.getAllRoles();
      return roles.cast<RoleEntity>();
    } catch (e) {
      print('❌ [RolesRepository] Error getting all roles: $e');
      rethrow;
    }
  }

  @override
  Future<RoleEntity> createRole(Map<String, dynamic> roleData) async {
    try {
      final role = await _dataSource.createRole(roleData);
      return role;
    } catch (e) {
      print('❌ [RolesRepository] Error creating role: $e');
      rethrow;
    }
  }

  @override
  Future<RoleEntity> updateRole(
    String roleId,
    Map<String, dynamic> roleData,
  ) async {
    try {
      final role = await _dataSource.updateRole(roleId, roleData);
      return role;
    } catch (e) {
      print('❌ [RolesRepository] Error updating role: $e');
      rethrow;
    }
  }

  @override
  Future<bool> deleteRole(String roleId) async {
    try {
      return await _dataSource.deleteRole(roleId);
    } catch (e) {
      print('❌ [RolesRepository] Error deleting role: $e');
      rethrow;
    }
  }

  @override
  Future<RoleEntity?> getRoleById(String roleId) async {
    try {
      final role = await _dataSource.getRoleById(roleId);
      return role;
    } catch (e) {
      print('❌ [RolesRepository] Error getting role by ID: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getAvailablePermissions() async {
    try {
      return await _dataSource.getAvailablePermissions();
    } catch (e) {
      print('❌ [RolesRepository] Error getting available permissions: $e');
      rethrow;
    }
  }
}
