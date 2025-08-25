import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fusion_launcher/core/image_loader_service.dart';
import 'package:fusion_launcher/core/models/algorithm/algorithm_metadata.dart';
import 'package:fusion_launcher/core/network_clients/rest_client/interceptor.dart';
import 'package:fusion_launcher/core/services/project_list_manager.dart';
import 'package:fusion_launcher/core/services/project_manager.dart';
import 'package:fusion_launcher/core/services/user_profile_manager.dart';
import 'package:fusion_launcher/features/dashboard/data/datasources/home_page_datasource.dart';
import 'package:fusion_launcher/features/dynamic_config/domain/usecases/get_panel_entity_usecase.dart';
import 'package:fusion_launcher/features/user_account_setup/data/datasources/auth_datasource.dart';
import 'package:fusion_launcher/features/user_account_setup/data/datasources/auth_datasource_impl.dart';
import 'package:fusion_launcher/features/user_account_setup/data/repositories/auth_repository_impl.dart';
import 'package:fusion_launcher/features/user_account_setup/domain/repositories/auth_repository.dart';
import 'package:fusion_launcher/features/user_account_setup/presentation/bloc/auth_bloc.dart';
import 'package:fusion_lib/di/service_locator.dart';
import 'package:fusion_lib/fusion_auth/fusion_auth.dart';
import 'package:fusion_lib/fusion_auth/fusion_auth_impl.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_networking/network/fusion_network_client.dart';
import 'package:fusion_lib/fusion_networking/network/rest_client/dio_client.dart';
import 'package:fusion_lib/models/fusion_models.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/dashboard/data/datasources/home_page_datasource_impl.dart';
import '../features/dashboard/data/repositories/home_page_repository_impl.dart';
import '../features/dashboard/domain/repositories/home_page_repository.dart';
import '../features/dashboard/domain/usecases/create_project_usecase.dart';
import '../features/dashboard/domain/usecases/delete_project_usecase.dart';
import '../features/dashboard/domain/usecases/fetch_file_usecase.dart';
import '../features/dashboard/domain/usecases/get_projects_data_usecase.dart';
import '../features/dashboard/domain/usecases/update_project_usecase.dart';
import '../features/dashboard/domain/usecases/upload_file_usecase.dart';
import '../features/dynamic_config/data/datasources/panel_datasource.dart';
import '../features/dynamic_config/data/datasources/panel_datasource_impl.dart';
import '../features/dynamic_config/data/repositories/panel_repository_impl.dart';
import '../features/dynamic_config/domain/repositories/panel_repository.dart';
import '../features/dynamic_config/domain/usecases/dispose_panel_usecase.dart';
import '../features/dynamic_config/domain/usecases/get_panel_data_usecase.dart';
import '../features/dynamic_config/domain/usecases/get_panel_stream_usecase.dart';
import '../features/dynamic_config/domain/usecases/initialize_panel_usecase.dart';
import '../features/dynamic_config/domain/usecases/reset_fusion_data_usecase.dart';
import '../features/dynamic_config/domain/usecases/send_widget_data_usecase.dart';
import '../features/dynamic_config/presentation/bloc/panel_bloc.dart';
import 'constants/algorithms_data.dart';
import 'models/floor_entity.dart';
import 'models/project_entity.dart';
import 'models/user_profile_model.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> setupServiceLocator() async {
  final Map<String, dynamic> jsonMap = jsonDecode(algoMetadataJSON);
  final FusionAlgorithmsConfig fusionAlgorithmsConfig = FusionAlgorithmsConfig.fromJson(jsonMap);
  serviceLocator.registerSingleton<FusionAlgorithmsConfig>(fusionAlgorithmsConfig);

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  serviceLocator.registerSingleton<SharedPreferences>(prefs);

  serviceLocator.registerSingleton<SharedPreferencesHandler>(SharedPreferencesHandler.getInstance(serviceLocator<SharedPreferences>()));

  final ProjectEntity initialProject = ProjectEntity(
    name: 'Default Project',
    floors: <Floor>[
      Floor(
        name: "Default Floor",
        floorPlan: FloorPlanEntity.defaultFloorPlan,
      ),
    ],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    metaData: "",
  );

  final UserProfile initialUserProfile = UserProfile(
    personalInfo: PersonalInfo(
      name: "",
      organization: "",
      jobTitle: "",
      phone: "",
    ),

    security: Security(
      username: "",
      password: "",
      isTwoFactorEnabled: false,
      enableEmailNotifications: false,
      enableSMSNotifications: false,
    ),
    address: Address(
      addressLine1: "",
      addressLine2: "",
      city: "",
      state: "",
      zipCode: "",
      country: "",
      timezone: "",
    ),
    measurementUnit: "",
    currency: "USD",
    language: "English (US)",
    notifications: Notifications(productUpdates: false, projectActivity: false, trainingAndResources: false),
    location: '',
  );
  serviceLocator.registerLazySingleton<PanelDataSource>(() => PanelDataSourceImpl());

  serviceLocator.registerLazySingleton<PanelRepository>(() => PanelRepositoryImpl());
  serviceLocator.registerLazySingleton<PanelBloc>(() => PanelBloc());

  serviceLocator.registerLazySingleton<GetPanelDataUseCase>(() => GetPanelDataUseCase());
  serviceLocator.registerLazySingleton<SendWidgetDataUseCase>(() => SendWidgetDataUseCase());
  serviceLocator.registerLazySingleton<InitializePanelUseCase>(() => InitializePanelUseCase());
  serviceLocator.registerLazySingleton<DisposePanelUseCase>(() => DisposePanelUseCase());
  serviceLocator.registerLazySingleton<GetPanelStreamUseCase>(() => GetPanelStreamUseCase());
  serviceLocator.registerLazySingleton<ResetFusionUseCase>(() => ResetFusionUseCase());
  serviceLocator.registerLazySingleton<GetPanelEntityUseCase>(() => GetPanelEntityUseCase());
  serviceLocator.registerLazySingleton<CreateProjectUseCase>(() => CreateProjectUseCase());
  serviceLocator.registerLazySingleton<UploadFileUseCase>(() => UploadFileUseCase());
  serviceLocator.registerLazySingleton<GetProjectsDataUseCase>(() => GetProjectsDataUseCase());
  serviceLocator.registerLazySingleton<DeleteProjectUseCase>(() => DeleteProjectUseCase());
  serviceLocator.registerLazySingleton<FetchFileUsecase>(() => FetchFileUsecase());
  serviceLocator.registerLazySingleton<UpdateProjectUsecase>(() => UpdateProjectUsecase());

  /// Registering the ProjectListManager with the initial project
  final ProjectListManager plm = ProjectListManager();
  serviceLocator.registerSingleton<ProjectListManager>(plm);
  plm.loadProjects();

  final ProjectManager pm = ProjectManager(initialProject);
  serviceLocator.registerSingleton<ProjectManager>(pm);
  // pm.loadProject();

  final UserProfileManager upm = UserProfileManager(initialUserProfile);
  serviceLocator.registerSingleton<UserProfileManager>(upm);

  serviceLocator.registerSingleton<ImageLoaderService>(
    ImageLoaderService(),
  );

  serviceLocator.registerSingleton<FusionBleCommands>(
    FusionBleCommandsImpl(),
  );

  serviceLocator.registerSingleton<DioClient>(
    DioClient(dioInstance: Dio(), interceptors: <Interceptor>[AppInterceptors()]),
  );

  //Register App Settings
  serviceLocator.registerSingleton<FusionPreferences>(FusionPreferences(sharedPreferencesHandler: serviceLocator<SharedPreferencesHandler>()));

  //register Telemetry manager
  serviceLocator.registerLazySingleton<TelemetryData>(() => TelemetryData());

  serviceLocator.registerSingleton<FusionNetworkClient>(
    FusionNetworkClient(
      httpClient: serviceLocator<DioClient>(),
      sharedPreferencesHandler: serviceLocator<SharedPreferencesHandler>(),
      telemetryData: serviceLocator<TelemetryData>(),
      fusionPreferences: serviceLocator<FusionPreferences>(),
    ),
  );

  serviceLocator.registerLazySingleton<FusionAuth>(() => FusionAuthImpl(fusionNetworkClient: serviceLocator<FusionNetworkClient>()));

  /// Registering the HomePageRepository and its use cases
  serviceLocator.registerLazySingleton<AuthDataSource>(() => AuthDataSourceImpl(fusionAuth: serviceLocator<FusionAuth>()));
  serviceLocator.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(serviceLocator<AuthDataSource>()));
  serviceLocator.registerLazySingleton<AuthBloc>(() => AuthBloc(repository: serviceLocator<AuthRepository>()));

  /// Registering the CreateProjectUseCase
  serviceLocator.registerLazySingleton<HomePageDatasource>(() => HomePageDatasourceImpl(serviceLocator<FusionNetworkClient>()));
  serviceLocator.registerLazySingleton<HomePageRepository>(() => HomePageRepositoryImpl(serviceLocator<HomePageDatasource>()));
  // serviceLocator.registerLazySingleton(() => CreateProjectUseCase(serviceLocator()));

  // TODO: ALWAYS KEEP THIS AT THE END OF THE FILE
  await setupFusionLib(serviceLocator);
}
