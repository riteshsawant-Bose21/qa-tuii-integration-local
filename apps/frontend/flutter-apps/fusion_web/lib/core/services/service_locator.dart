import 'package:fusion_web/core/services/api_service.dart';
import 'package:fusion_web/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:fusion_web/features/auth/data/datasources/auth0_datasource.dart';
import 'package:fusion_web/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fusion_web/features/auth/domain/usecases/auth_usecases.dart';
import 'package:fusion_web/features/organizations/data/datasources/organizations_datasource.dart';
import 'package:fusion_web/features/organizations/data/repositories/organizations_repository_impl.dart';
import 'package:fusion_web/features/organizations/presentation/viewmodels/organizations_viewmodel.dart';
import 'package:fusion_web/features/organizations/domain/usecases/organizations_usecases.dart';
import 'package:fusion_web/features/projects/data/datasources/project_datasource.dart';
import 'package:fusion_web/features/projects/data/repositories/projects_repository_impl.dart';
import 'package:fusion_web/features/projects/presentation/viewmodels/projects_viewmodel.dart';
import 'package:fusion_web/features/users/data/datasources/users_datasource.dart';
import 'package:fusion_web/features/users/data/repositories/users_repository_impl.dart';
import 'package:fusion_web/features/users/presentation/viewmodels/users_viewmodel.dart';
import 'package:fusion_web/features/users/domain/usecases/users_usecases.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  ApiService? _apiService;
  AuthViewModel? _authViewModel;
  OrganizationsViewModel? _organizationsViewModel;
  ProjectsViewModel? _projectsViewModel;
  UsersViewModel? _usersViewModel;

  // ================= REPOSITORIES =================
  AuthRepositoryImpl? _authRepository;
  OrganizationsRepositoryImpl? _organizationsRepository;
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

      final localDataSource = ProjectsLocalDataSource();

      final repository = ProjectsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      _projectsViewModel = ProjectsViewModel(repository: repository);
    }

    return _projectsViewModel!;
  }

  // ================= USERS VIEWMODEL (SINGLETON) =================
  UsersViewModel get usersViewModel {
    if (_usersViewModel == null) {
      final remoteDataSource = UsersRemoteDataSource(apiService: apiService);
      final localDataSource = UsersLocalDataSource();

      final repository = UsersRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      _usersViewModel = UsersViewModel(
        getUsersUseCase: GetUsersUseCase(repository),
        getUserByIdUseCase: GetUserByIdUseCase(repository),
        createUserUseCase: CreateUserUseCase(repository),
        updateUserUseCase: UpdateUserUseCase(repository),
        deleteUserUseCase: DeleteUserUseCase(repository),
        searchUsersUseCase: SearchUsersUseCase(repository),
        inviteUserUseCase: InviteUserUseCase(repository),
        resendInviteUseCase: ResendInviteUseCase(repository),
        updateUserRolesUseCase: UpdateUserRolesUseCase(repository),
        assignUserToProjectsUseCase: AssignUserToProjectsUseCase(repository),
        removeUserFromProjectsUseCase: RemoveUserFromProjectsUseCase(
          repository,
        ),
        activateUserUseCase: ActivateUserUseCase(repository),
        deactivateUserUseCase: DeactivateUserUseCase(repository),
        filterUsersUseCase: FilterUsersUseCase(repository),
        getUserMetricsUseCase: GetUserMetricsUseCase(repository),
      );
    }

    return _usersViewModel!;
  }

  // ================= ORGANIZATIONS VIEWMODEL (SINGLETON) =================
  OrganizationsViewModel get organizationsViewModel {
    if (_organizationsViewModel == null) {
      final remoteDataSource = OrganizationsRemoteDataSource(
        apiService: apiService,
      );
      final localDataSource = OrganizationsLocalDataSource();

      final repository = OrganizationsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      _organizationsViewModel = OrganizationsViewModel(
        getOrganizationsUseCase: GetOrganizationsUseCase(repository),
        getOrganizationByIdUseCase: GetOrganizationByIdUseCase(repository),
        createOrganizationUseCase: CreateOrganizationUseCase(repository),
        updateOrganizationUseCase: UpdateOrganizationUseCase(repository),
        deleteOrganizationUseCase: DeleteOrganizationUseCase(repository),
        searchOrganizationsUseCase: SearchOrganizationsUseCase(repository),
        filterOrganizationsUseCase: FilterOrganizationsUseCase(repository),
        getOrganizationMetricsUseCase: GetOrganizationMetricsUseCase(
          repository,
        ),
        getOrganizationUsersUseCase: GetOrganizationUsersUseCase(repository),
        getOrganizationProjectsUseCase: GetOrganizationProjectsUseCase(
          repository,
        ),
        activateOrganizationUseCase: ActivateOrganizationUseCase(repository),
        deactivateOrganizationUseCase: DeactivateOrganizationUseCase(
          repository,
        ),
      );
    }

    return _organizationsViewModel!;
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
      final localDataSource = ProjectsLocalDataSource();

      _projectsRepository = ProjectsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
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

  // ================= ORGANIZATIONS REPOSITORY =================
  OrganizationsRepositoryImpl get organizationsRepository {
    if (_organizationsRepository == null) {
      final remoteDataSource = OrganizationsRemoteDataSource(
        apiService: apiService,
      );
      final localDataSource = OrganizationsLocalDataSource();

      _organizationsRepository = OrganizationsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );
    }
    return _organizationsRepository!;
  }

  // ================= RESET =================
  void reset() {
    _apiService?.dispose();
    _apiService = null;
    _authViewModel = null;
    _organizationsViewModel = null;
    _projectsViewModel = null;
    _usersViewModel = null;
    _authRepository = null;
    _organizationsRepository = null;
    _projectsRepository = null;
    _usersRepository = null;
  }

  void dispose() {
    _apiService?.dispose();
    _authViewModel = null;
    _projectsViewModel = null;
    _usersViewModel = null;
    _authRepository = null;
    _projectsRepository = null;
    _usersRepository = null;
  }
}
