import 'package:fusion_web/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> login();
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
  Future<bool> isLoggedIn();
}
