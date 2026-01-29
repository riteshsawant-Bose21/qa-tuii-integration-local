import 'package:fusion_web/features/auth/data/datasources/auth0_datasource.dart';
import 'package:fusion_web/features/auth/domain/entities/user_entity.dart';
import 'package:fusion_web/features/auth/domain/repositories/auth_repository.dart';
import 'package:fusion_web/core/services/service_locator.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Auth0DataSource dataSource;

  AuthRepositoryImpl({Auth0DataSource? dataSource})
    : dataSource =
          dataSource ??
          Auth0DataSource(apiService: ServiceLocator().apiService);

  @override
  Future<UserEntity?> login() async {
    return await dataSource.login();
  }

  @override
  Future<void> logout() async {
    return await dataSource.logout();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return await dataSource.getCurrentUser();
  }

  @override
  Future<bool> isLoggedIn() async {
    final credentials = await dataSource.getIdToken();
    return credentials != null;
  }

  Future<String?> getIdToken() async {
    return await dataSource.getIdToken();
  }
}
