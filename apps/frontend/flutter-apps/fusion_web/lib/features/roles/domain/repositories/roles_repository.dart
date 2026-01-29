import 'package:fusion_web/features/roles/domain/entities/role_entity.dart';

abstract class RolesRepository {
  Future<List<RoleEntity>> getAllRoles();
  Future<RoleEntity> createRole(Map<String, dynamic> roleData);
  Future<RoleEntity> updateRole(String roleId, Map<String, dynamic> roleData);
  Future<bool> deleteRole(String roleId);
  Future<RoleEntity?> getRoleById(String roleId);
  Future<List<String>> getAvailablePermissions();
}
