import 'package:fusion_web/core/services/api_service.dart';
import 'package:fusion_web/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:fusion_web/features/auth/data/datasources/auth0_datasource.dart';
import 'package:fusion_web/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fusion_web/features/auth/domain/usecases/auth_usecases.dart';
import 'package:fusion_web/features/projects/data/datasources/project_datasource.dart';
import 'package:fusion_web/features/projects/data/repositories/projects_repository_impl.dart';
import 'package:fusion_web/features/projects/presentation/viewmodels/projects_viewmodel.dart';
import 'package:fusion_web/features/users/data/datasources/users_datasource.dart';
import 'package:fusion_web/features/users/data/repositories/users_repository_impl.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  ApiService? _apiService;
  AuthViewModel? _authViewModel;
  ProjectsViewModel? _projectsViewModel;

  // ================= REPOSITORIES =================
  AuthRepositoryImpl? _authRepository;
  ProjectsRepositoryImpl? _projectsRepository;
  UsersRepositoryImpl? _usersRepository;

  // ================= API SERVICE =================
  ApiService get apiService {
    _apiService ??= ApiService();
    return _apiService!;
  }

  // ================= AUTH VIEWMODEL =================
  AuthViewModel get authViewModel {
    if (_authViewModel == null) {
      final dataSource = Auth0DataSource();
      final repository = AuthRepositoryImpl(dataSource: dataSource);

      _authViewModel = AuthViewModel(
        loginUseCase: LoginUseCase(repository),
        logoutUseCase: LogoutUseCase(repository),
        getCurrentUserUseCase: GetCurrentUserUseCase(repository),
        isLoggedInUseCase: IsLoggedInUseCase(repository),
        authRepository: repository,
      );
    }
    return _authViewModel!;
  }

  // ================= PROJECTS VIEWMODEL (SINGLETON) =================
  ProjectsViewModel get projectsViewModel {
    if (_projectsViewModel == null) {
      final remoteDataSource = ProjectsRemoteDataSource(apiService: apiService);

      final repository = ProjectsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        // localDataSource: localDataSource,
      );

      _projectsViewModel = ProjectsViewModel(repository: repository);
    }

    return _projectsViewModel!;
  }

  // ================= AUTH REPOSITORY =================
  AuthRepositoryImpl get authRepository {
    _authRepository ??= AuthRepositoryImpl(dataSource: Auth0DataSource());
    return _authRepository!;
  }

  // ================= PROJECTS REPOSITORY =================
  ProjectsRepositoryImpl get projectsRepository {
    if (_projectsRepository == null) {
      final remoteDataSource = ProjectsRemoteDataSource(apiService: apiService);

      _projectsRepository = ProjectsRepositoryImpl(
        remoteDataSource: remoteDataSource,
      );
    }
    return _projectsRepository!;
  }

  // ================= USERS REPOSITORY =================
  UsersRepositoryImpl get usersRepository {
    if (_usersRepository == null) {
      final remoteDataSource = UsersRemoteDataSource(apiService: apiService);
      final localDataSource = UsersLocalDataSource();

      _usersRepository = UsersRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );
    }
    return _usersRepository!;
  }

  // ================= RESET =================
  void reset() {
    _apiService?.dispose();
    _apiService = null;
    _authViewModel = null;
    _projectsViewModel = null;
    _authRepository = null;
    _projectsRepository = null;
    _usersRepository = null;
  }

  void dispose() {
    _apiService?.dispose();
    _authViewModel = null;
    _projectsViewModel = null;
    _authRepository = null;
    _projectsRepository = null;
    _usersRepository = null;
  }
}
