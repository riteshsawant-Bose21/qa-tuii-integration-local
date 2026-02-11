import 'package:fusion_web/features/users/domain/entities/user_entity.dart';

// Invite User Parameters
class InviteUserParams {
  final String email;
  final String name;
  final List<String> roles;
  final List<String> projectIds;
  final UserType userType;

  const InviteUserParams({
    required this.email,
    required this.name,
    required this.roles,
    this.projectIds = const [],
    required this.userType,
  });
}

// Update User Role Parameters
class UpdateUserRoleParams {
  final String userId;
  final List<String> roles;

  const UpdateUserRoleParams({required this.userId, required this.roles});
}

// Filter Parameters
class UserFilterParams {
  final String? role;
  final UserStatus? status;
  final DateTime? lastLoginStart;
  final DateTime? lastLoginEnd;
  final String? projectId;
  final UserType? userType;

  const UserFilterParams({
    this.role,
    this.status,
    this.lastLoginStart,
    this.lastLoginEnd,
    this.projectId,
    this.userType,
  });
}

// Repository interface - Domain layer doesn't know about implementation
abstract class UsersRepository {
  Future<List<UserEntity>> getUsers();
  Future<UserEntity> getUserById(String id);
  Future<UserEntity> createUser(UserEntity user);
  Future<UserEntity> updateUser(UserEntity user);
  Future<void> deleteUser(String id);
  Future<List<UserEntity>> searchUsers(String query);

  // New methods for enhanced user management
  Future<UserEntity> inviteUser(InviteUserParams params);
  Future<void> resendInvite(String userId);
  Future<UserEntity> updateUserRoles(UpdateUserRoleParams params);
  Future<UserEntity> assignUserToProjects(
    String userId,
    List<String> projectIds,
  );
  Future<UserEntity> removeUserFromProjects(
    String userId,
    List<String> projectIds,
  );
  Future<UserEntity> activateUser(String userId);
  Future<UserEntity> deactivateUser(String userId);
  Future<List<UserEntity>> filterUsers(UserFilterParams params);
  Future<Map<String, int>> getUserMetrics();
}
