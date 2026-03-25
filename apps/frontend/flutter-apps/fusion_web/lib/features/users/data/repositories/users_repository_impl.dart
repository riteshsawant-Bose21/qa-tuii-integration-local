import 'package:fusion_web/features/users/data/datasources/users_datasource.dart';
import 'package:fusion_web/features/users/data/models/user_model.dart';
import 'package:fusion_web/features/users/domain/entities/user_entity.dart';
import 'package:fusion_web/features/users/domain/repositories/users_repository.dart';

class UsersRepositoryImpl implements UsersRepository {
  final UsersRemoteDataSource remoteDataSource;
  final UsersLocalDataSource localDataSource;

  const UsersRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  UserModel _entityToModel(UserEntity user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      roles: user.roles,
      status: user.status,
      userType: user.userType,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
      inviteDate: user.inviteDate,
      avatar: user.avatar,
      permissions: user.permissions,
      associatedProjects: user.associatedProjects,
      organizationId: user.organizationId,
      phone: user.phone,
      activityHistory: user.activityHistory,
      isActive: user.isActive,
    );
  }

  @override
  Future<List<UserEntity>> getUsers() async {
    try {
      final remoteData = await remoteDataSource.getUsers();
      localDataSource.cacheUsers(remoteData);
      return remoteData;
    } catch (e) {
      try {
        return await localDataSource.getUsers();
      } catch (e) {
        return UserModel.mockUsers();
      }
    }
  }

  @override
  Future<UserEntity> getUserById(String id) async {
    try {
      return await remoteDataSource.getUserById(id);
    } catch (e) {
      try {
        return await localDataSource.getUserById(id);
      } catch (e) {
        return UserModel.mockUsers().first;
      }
    }
  }

  @override
  Future<UserEntity> createUser(UserEntity user) async {
    final userModel = _entityToModel(user);

    try {
      final result = await remoteDataSource.createUser(userModel);
      await localDataSource.createUser(result);
      return result;
    } catch (e) {
      return await localDataSource.createUser(userModel);
    }
  }

  @override
  Future<UserEntity> updateUser(UserEntity user) async {
    final userModel = _entityToModel(user);

    try {
      final result = await remoteDataSource.updateUser(userModel);
      await localDataSource.updateUser(result);
      return result;
    } catch (e) {
      return await localDataSource.updateUser(userModel);
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      await remoteDataSource.deleteUser(id);
      await localDataSource.deleteUser(id);
    } catch (e) {
      await localDataSource.deleteUser(id);
    }
  }

  @override
  Future<List<UserEntity>> searchUsers(String query) async {
    try {
      return await remoteDataSource.searchUsers(query);
    } catch (e) {
      try {
        return await localDataSource.searchUsers(query);
      } catch (e) {
        final users = UserModel.mockUsers();
        return users
            .where(
              (u) =>
                  u.name.toLowerCase().contains(query.toLowerCase()) ||
                  u.email.toLowerCase().contains(query.toLowerCase()) ||
                  u.role.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    }
  }

  @override
  Future<UserEntity> inviteUser(InviteUserParams params) async {
    try {
      return await remoteDataSource.inviteUser(params);
    } catch (e) {
      // Create a mock invited user for local testing
      final newUser = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: params.name,
        email: params.email,
        roles: params.roles,
        status: UserStatus.invited,
        userType: params.userType,
        createdAt: DateTime.now(),
        inviteDate: DateTime.now(),
        permissions: ['read'],
        associatedProjects: params.projectIds,
        isActive: false,
      );
      await localDataSource.createUser(newUser);
      return newUser;
    }
  }

  @override
  Future<void> resendInvite(String userId) async {
    try {
      await remoteDataSource.resendInvite(userId);
    } catch (e) {
      // Simulate resend locally
      print('Resending invite for user: $userId');
    }
  }

  @override
  Future<void> inviteUsersToOrganization(
    String organizationId,
    List<Map<String, String>> users,
  ) async {
    try {
      await remoteDataSource.inviteUsersToOrganization(organizationId, users);
    } catch (e) {
      throw Exception('Failed to invite users to organization: $e');
    }
  }

  @override
  Future<UserEntity> updateUserRoles(UpdateUserRoleParams params) async {
    try {
      return await remoteDataSource.updateUserRoles(params);
    } catch (e) {
      final user = await getUserById(params.userId);
      final updatedUser = user.copyWith(roles: params.roles);
      return await updateUser(updatedUser);
    }
  }

  @override
  Future<UserEntity> assignUserToProjects(
    String userId,
    List<String> projectIds,
  ) async {
    try {
      return await remoteDataSource.assignUserToProjects(userId, projectIds);
    } catch (e) {
      final user = await getUserById(userId);
      final updatedProjects = [
        ...user.associatedProjects,
        ...projectIds,
      ].toSet().toList();
      final updatedUser = user.copyWith(associatedProjects: updatedProjects);
      return await updateUser(updatedUser);
    }
  }

  @override
  Future<UserEntity> removeUserFromProjects(
    String userId,
    List<String> projectIds,
  ) async {
    try {
      return await remoteDataSource.removeUserFromProjects(userId, projectIds);
    } catch (e) {
      final user = await getUserById(userId);
      final updatedProjects = user.associatedProjects
          .where((projectId) => !projectIds.contains(projectId))
          .toList();
      final updatedUser = user.copyWith(associatedProjects: updatedProjects);
      return await updateUser(updatedUser);
    }
  }

  @override
  Future<UserEntity> activateUser(String userId) async {
    try {
      return await remoteDataSource.activateUser(userId);
    } catch (e) {
      final user = await getUserById(userId);
      final updatedUser = user.copyWith(
        status: UserStatus.active,
        isActive: true,
      );
      return await updateUser(updatedUser);
    }
  }

  @override
  Future<UserEntity> deactivateUser(String userId) async {
    try {
      return await remoteDataSource.deactivateUser(userId);
    } catch (e) {
      final user = await getUserById(userId);
      final updatedUser = user.copyWith(
        status: UserStatus.inactive,
        isActive: false,
      );
      return await updateUser(updatedUser);
    }
  }

  @override
  Future<List<UserEntity>> filterUsers(UserFilterParams params) async {
    try {
      return await remoteDataSource.filterUsers(params);
    } catch (e) {
      final users = await getUsers();
      var filtered = users;

      if (params.role != null) {
        filtered = filtered
            .where((u) => u.roles.contains(params.role))
            .toList();
      }
      if (params.status != null) {
        filtered = filtered.where((u) => u.status == params.status).toList();
      }
      if (params.userType != null) {
        filtered = filtered
            .where((u) => u.userType == params.userType)
            .toList();
      }
      if (params.projectId != null) {
        filtered = filtered
            .where((u) => u.associatedProjects.contains(params.projectId))
            .toList();
      }
      if (params.lastLoginStart != null && params.lastLoginEnd != null) {
        filtered = filtered.where((u) {
          if (u.lastLoginAt == null) return false;
          return u.lastLoginAt!.isAfter(params.lastLoginStart!) &&
              u.lastLoginAt!.isBefore(params.lastLoginEnd!);
        }).toList();
      }

      return filtered;
    }
  }

  @override
  Future<Map<String, int>> getUserMetrics() async {
    try {
      return await remoteDataSource.getUserMetrics();
    } catch (e) {
      final users = await getUsers();
      return {
        'total': users.length,
        'active': users.where((u) => u.status == UserStatus.active).length,
        'invited': users.where((u) => u.status == UserStatus.invited).length,
        'pending': users.where((u) => u.status == UserStatus.pending).length,
        'inactive': users.where((u) => u.status == UserStatus.inactive).length,
      };
    }
  }
}
