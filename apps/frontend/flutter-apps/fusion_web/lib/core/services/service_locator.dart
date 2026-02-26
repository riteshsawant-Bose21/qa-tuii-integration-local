// // import 'package:fusion_web/core/services/api_service.dart';
// // import 'package:fusion_web/features/auth/presentation/viewmodels/auth_viewmodel.dart';
// // import 'package:fusion_web/features/auth/data/datasources/auth0_datasource.dart';
// // import 'package:fusion_web/features/auth/data/repositories/auth_repository_impl.dart';
// // import 'package:fusion_web/features/auth/domain/usecases/auth_usecases.dart';
// // import 'package:fusion_web/features/projects/data/datasources/project_datasource.dart';
// // import 'package:fusion_web/features/projects/data/repositories/projects_repository_impl.dart';
// // import 'package:fusion_web/features/projects/presentation/viewmodels/projects_viewmodel.dart';

// // class ServiceLocator {
// //   static final ServiceLocator _instance = ServiceLocator._internal();
// //   factory ServiceLocator() => _instance;
// //   ServiceLocator._internal();

// //   ApiService? _apiService;
// //   AuthViewModel? _authViewModel;

// //   ApiService get apiService {
// //     _apiService ??= ApiService();
// //     return _apiService!;
// //   }

// //   AuthViewModel get authViewModel {
// //     if (_authViewModel == null) {
// //       final dataSource = Auth0DataSource();
// //       final repository = AuthRepositoryImpl(dataSource: dataSource);

// //       _authViewModel = AuthViewModel(
// //         loginUseCase: LoginUseCase(repository),
// //         logoutUseCase: LogoutUseCase(repository),
// //         getCurrentUserUseCase: GetCurrentUserUseCase(repository),
// //         isLoggedInUseCase: IsLoggedInUseCase(repository),
// //         authRepository: repository,
// //       );
// //     }
// //     return _authViewModel!;
// //   }

// //   void reset() {
// //     _apiService?.dispose();
// //     _apiService = null;
// //     _authViewModel = null;
// //   }

// //   void dispose() {
// //     _apiService?.dispose();
// //     _authViewModel = null;
// //   }
// // }

// import 'package:fusion_web/core/services/api_service.dart';
// import 'package:fusion_web/features/auth/presentation/viewmodels/auth_viewmodel.dart';
// import 'package:fusion_web/features/auth/data/datasources/auth0_datasource.dart';
// import 'package:fusion_web/features/auth/data/repositories/auth_repository_impl.dart';
// import 'package:fusion_web/features/auth/domain/usecases/auth_usecases.dart';
// import 'package:fusion_web/features/projects/data/datasources/project_datasource.dart';
// import 'package:fusion_web/features/projects/data/repositories/projects_repository_impl.dart';
// import 'package:fusion_web/features/projects/presentation/viewmodels/projects_viewmodel.dart';

// class ServiceLocator {
//   static final ServiceLocator _instance = ServiceLocator._internal();
//   factory ServiceLocator() => _instance;
//   ServiceLocator._internal();

//   ApiService? _apiService;
//   AuthViewModel? _authViewModel;

//   ApiService get apiService {
//     _apiService ??= ApiService();
//     return _apiService!;
//   }

//   AuthViewModel get authViewModel {
//     if (_authViewModel == null) {
//       final dataSource = Auth0DataSource();
//       final repository = AuthRepositoryImpl(dataSource: dataSource);

//       _authViewModel = AuthViewModel(
//         loginUseCase: LoginUseCase(repository),
//         logoutUseCase: LogoutUseCase(repository),
//         getCurrentUserUseCase: GetCurrentUserUseCase(repository),
//         isLoggedInUseCase: IsLoggedInUseCase(repository),
//         authRepository: repository,
//       );
//     }
//     return _authViewModel!;
//   }

//   // ✅ MOVE THIS INSIDE THE CLASS
//   ProjectsViewModel createProjectsViewModel() {
//     final remoteDataSource =
//         ProjectsRemoteDataSource(apiService: apiService);

//     final localDataSource = ProjectsLocalDataSource();

//     final repository = ProjectsRepositoryImpl(
//       remoteDataSource: remoteDataSource,
//       localDataSource: localDataSource,
//     );

//     final vm = ProjectsViewModel(repository: repository);
//     vm.initialize();
//     return vm;
//   }

//   void reset() {
//     _apiService?.dispose();
//     _apiService = null;
//     _authViewModel = null;
//   }

//   void dispose() {
//     _apiService?.dispose();
//     _authViewModel = null;
//   }
// }


import 'package:fusion_web/core/services/api_service.dart';
import 'package:fusion_web/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:fusion_web/features/auth/data/datasources/auth0_datasource.dart';
import 'package:fusion_web/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fusion_web/features/auth/domain/usecases/auth_usecases.dart';
import 'package:fusion_web/features/projects/data/datasources/project_datasource.dart';
import 'package:fusion_web/features/projects/data/repositories/projects_repository_impl.dart';
import 'package:fusion_web/features/projects/presentation/viewmodels/projects_viewmodel.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  ApiService? _apiService;
  AuthViewModel? _authViewModel;
  ProjectsViewModel? _projectsViewModel; // ✅ NEW

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
      final remoteDataSource =
          ProjectsRemoteDataSource(apiService: apiService);

      final localDataSource = ProjectsLocalDataSource();

      final repository = ProjectsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      _projectsViewModel = ProjectsViewModel(repository: repository);
    }

    return _projectsViewModel!;
  }

  // ================= RESET =================
  void reset() {
    _apiService?.dispose();
    _apiService = null;
    _authViewModel = null;
    _projectsViewModel = null; // ✅ IMPORTANT
  }

  void dispose() {
    _apiService?.dispose();
    _authViewModel = null;
    _projectsViewModel = null;
  }
}