import 'package:fusion_web/features/users/domain/entities/user_entity.dart';

// Repository interface - Domain layer doesn't know about implementation
abstract class UsersRepository {
  Future<List<UserEntity>> getUsers();
  Future<UserEntity> getUserById(String id);
  Future<UserEntity> createUser(UserEntity user);
  Future<UserEntity> updateUser(UserEntity user);
  Future<void> deleteUser(String id);
  Future<List<UserEntity>> searchUsers(String query);
}
