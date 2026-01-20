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
    final userModel = UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      status: user.status,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
      avatar: user.avatar,
      permissions: user.permissions,
    );

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
    final userModel = UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      status: user.status,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
      avatar: user.avatar,
      permissions: user.permissions,
    );

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
}
