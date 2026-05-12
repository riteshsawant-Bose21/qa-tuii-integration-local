import 'package:fusion_web/features/auth/domain/entities/user_entity.dart';
import 'package:fusion_web/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<UserEntity?> call() async {
    return await repository.login();
  }
}

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<void> call() async {
    return await repository.logout();
  }
}

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<UserEntity?> call() async {
    return await repository.getCurrentUser();
  }
}

class IsLoggedInUseCase {
  final AuthRepository repository;

  IsLoggedInUseCase(this.repository);

  Future<bool> call() async {
    return await repository.isLoggedIn();
  }
}
