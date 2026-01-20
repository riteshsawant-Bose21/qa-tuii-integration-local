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
