import 'package:fusion_web/core/usecases/usecase.dart';
import 'package:fusion_web/features/users/domain/entities/user_entity.dart';
import 'package:fusion_web/features/users/domain/repositories/users_repository.dart';

class GetUsersUseCase implements UseCase<List<UserEntity>, NoParams> {
  final UsersRepository repository;

  const GetUsersUseCase(this.repository);

  @override
  Future<List<UserEntity>> call(NoParams params) async {
    return await repository.getUsers();
  }
}

class GetUserByIdUseCase implements UseCase<UserEntity, String> {
  final UsersRepository repository;

  const GetUserByIdUseCase(this.repository);

  @override
  Future<UserEntity> call(String id) async {
    return await repository.getUserById(id);
  }
}

class CreateUserUseCase implements UseCase<UserEntity, UserEntity> {
  final UsersRepository repository;

  const CreateUserUseCase(this.repository);

  @override
  Future<UserEntity> call(UserEntity user) async {
    return await repository.createUser(user);
  }
}

class UpdateUserUseCase implements UseCase<UserEntity, UserEntity> {
  final UsersRepository repository;

  const UpdateUserUseCase(this.repository);

  @override
  Future<UserEntity> call(UserEntity user) async {
    return await repository.updateUser(user);
  }
}

class DeleteUserUseCase implements UseCase<void, String> {
  final UsersRepository repository;

  const DeleteUserUseCase(this.repository);

  @override
  Future<void> call(String id) async {
    return await repository.deleteUser(id);
  }
}

class SearchUsersUseCase implements UseCase<List<UserEntity>, String> {
  final UsersRepository repository;

  const SearchUsersUseCase(this.repository);

  @override
  Future<List<UserEntity>> call(String query) async {
    return await repository.searchUsers(query);
  }
}

// New Use Cases for Enhanced User Management

class InviteUserUseCase implements UseCase<UserEntity, InviteUserParams> {
  final UsersRepository repository;

  const InviteUserUseCase(this.repository);

  @override
  Future<UserEntity> call(InviteUserParams params) async {
    return await repository.inviteUser(params);
  }
}

class ResendInviteUseCase implements UseCase<void, String> {
  final UsersRepository repository;

  const ResendInviteUseCase(this.repository);

  @override
  Future<void> call(String userId) async {
    return await repository.resendInvite(userId);
  }
}

class UpdateUserRolesUseCase
    implements UseCase<UserEntity, UpdateUserRoleParams> {
  final UsersRepository repository;

  const UpdateUserRolesUseCase(this.repository);

  @override
  Future<UserEntity> call(UpdateUserRoleParams params) async {
    return await repository.updateUserRoles(params);
  }
}

class AssignUserToProjectsParams {
  final String userId;
  final List<String> projectIds;

  const AssignUserToProjectsParams({
    required this.userId,
    required this.projectIds,
  });
}

class AssignUserToProjectsUseCase
    implements UseCase<UserEntity, AssignUserToProjectsParams> {
  final UsersRepository repository;

  const AssignUserToProjectsUseCase(this.repository);

  @override
  Future<UserEntity> call(AssignUserToProjectsParams params) async {
    return await repository.assignUserToProjects(
      params.userId,
      params.projectIds,
    );
  }
}

class RemoveUserFromProjectsParams {
  final String userId;
  final List<String> projectIds;

  const RemoveUserFromProjectsParams({
    required this.userId,
    required this.projectIds,
  });
}

class RemoveUserFromProjectsUseCase
    implements UseCase<UserEntity, RemoveUserFromProjectsParams> {
  final UsersRepository repository;

  const RemoveUserFromProjectsUseCase(this.repository);

  @override
  Future<UserEntity> call(RemoveUserFromProjectsParams params) async {
    return await repository.removeUserFromProjects(
      params.userId,
      params.projectIds,
    );
  }
}

class ActivateUserUseCase implements UseCase<UserEntity, String> {
  final UsersRepository repository;

  const ActivateUserUseCase(this.repository);

  @override
  Future<UserEntity> call(String userId) async {
    return await repository.activateUser(userId);
  }
}

class DeactivateUserUseCase implements UseCase<UserEntity, String> {
  final UsersRepository repository;

  const DeactivateUserUseCase(this.repository);

  @override
  Future<UserEntity> call(String userId) async {
    return await repository.deactivateUser(userId);
  }
}

class FilterUsersUseCase
    implements UseCase<List<UserEntity>, UserFilterParams> {
  final UsersRepository repository;

  const FilterUsersUseCase(this.repository);

  @override
  Future<List<UserEntity>> call(UserFilterParams params) async {
    return await repository.filterUsers(params);
  }
}

class GetUserMetricsUseCase implements UseCase<Map<String, int>, NoParams> {
  final UsersRepository repository;

  const GetUserMetricsUseCase(this.repository);

  @override
  Future<Map<String, int>> call(NoParams params) async {
    return await repository.getUserMetrics();
  }
}
