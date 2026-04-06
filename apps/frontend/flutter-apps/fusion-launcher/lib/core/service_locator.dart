import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fusion_launcher/core/config/app_config.dart';
import 'package:fusion_launcher/core/image_loader_service.dart';
import 'package:fusion_launcher/core/models/algorithm/algorithm_metadata.dart';
import 'package:fusion_launcher/core/network_clients/rest_client/interceptor.dart';
import 'package:fusion_launcher/core/services/app_cache_service.dart';
import 'package:fusion_launcher/core/services/user_profile_manager.dart';
import 'package:fusion_launcher/features/authentication/viewmodel/auth_view_model.dart';
import 'package:fusion_launcher/features/dynamic_config/domain/usecases/get_panel_entity_usecase.dart';
import 'package:fusion_launcher/features/projects/view_model/dsp_sync/config_sync_view_model.dart';
import 'package:fusion_launcher/features/projects/view_model/project_sync_view_model.dart';
import 'package:fusion_launcher/features/speaker_selection_popup/viewmodel/product_query_view_model.dart';
import 'package:fusion_lib/di/service_locator.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_networking/network/rest_client/dio_client.dart';
import 'package:fusion_lib/service/auth/fusion_auth_service.dart';
import 'package:fusion_lib/service/dro/dro_config_service.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/authentication/viewmodel/session_view_model.dart';
import '../features/configuration/presentation/viewmodel/project_view_model.dart';
import '../features/devices/view_model/firmware_update/firmware_update_vm.dart';
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
import '../features/home/domain/usecases/create_project_usecase.dart';
import '../features/home/domain/usecases/delete_project_usecase.dart';
import '../features/home/domain/usecases/fetch_file_usecase.dart';
import '../features/home/domain/usecases/get_projects_data_usecase.dart';
import '../features/home/domain/usecases/update_project_usecase.dart';
import '../features/home/domain/usecases/upload_file_usecase.dart';
import '../features/product_query/presentation/viewModel/product_query_view_model_cubit.dart';
import '../features/projects/view_model/block_data/block_data_viewmodel.dart';
import '../features/projects/view_model/meter_data/meter_data_view_model.dart';
import 'constants/algorithms_data.dart';
import 'models/user_profile_model.dart';
import 'router/navigation_observer.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> setupServiceLocator() async {
  final Map<String, dynamic> jsonMap = jsonDecode(algoMetadataJSON);
  final FusionAlgorithmsConfig fusionAlgorithmsConfig = FusionAlgorithmsConfig.fromJson(jsonMap);
  serviceLocator.registerSingleton<FusionAlgorithmsConfig>(fusionAlgorithmsConfig);

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  serviceLocator.registerSingleton<SharedPreferences>(prefs);

  final AppCacheService appCacheService = await AppCacheService.create();
  serviceLocator.registerSingleton<AppCacheService>(appCacheService);

  serviceLocator.registerSingleton<SharedPreferencesHandler>(SharedPreferencesHandler.getInstance(serviceLocator<SharedPreferences>()));

  serviceLocator.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  serviceLocator.registerSingleton<WebSocketService>(WebSocketService());

  serviceLocator.registerLazySingleton<FusionSecureStorage>(
    () => FusionSecureStorageImpl(serviceLocator<FlutterSecureStorage>()),
  );

  serviceLocator.registerSingleton<DioClient>(
    DioClient(dioInstance: Dio(), interceptors: <Interceptor>[AppInterceptors()]),
  );

  //register Telemetry manager
  serviceLocator.registerLazySingleton<TelemetryData>(() => TelemetryData());

  serviceLocator.registerLazySingleton<FusionAuthService>(
    () => FusionAuthService(
      domain: AppConfig.auth0Domain,
      clientId: AppConfig.auth0ClientId,
      secureStorage: serviceLocator<FusionSecureStorage>(),
      authScheme: AppConfig.auth0Schema,
      webRedirectUrl: AppConfig.auth0RedirectUri,
      nativeRedirectUrl: AppConfig.auth0NativeRedirectUri,
    ),
  );

  serviceLocator.registerSingleton<FusionNetworkClient>(
    FusionNetworkClient(
      httpClient: serviceLocator<DioClient>(),
      sharedPreferencesHandler: serviceLocator<SharedPreferencesHandler>(),
      telemetryData: serviceLocator<TelemetryData>(),
      fusionAuthService: serviceLocator<FusionAuthService>(),
      secureStorageService: serviceLocator<FusionSecureStorage>(),
      apiBaseUrl: AppConfig.awsApiBaseUrl,
      webSocketService: serviceLocator<WebSocketService>(),
    ),
  );

  serviceLocator.registerSingleton<MdnsService>(
    MdnsService(serviceType: '_fusion._tcp.local'),
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

  final UserProfileManager upm = UserProfileManager(initialUserProfile);
  serviceLocator.registerSingleton<UserProfileManager>(upm);

  serviceLocator.registerSingleton<ImageLoaderService>(
    ImageLoaderService(),
  );

  serviceLocator.registerSingleton<FusionBleCommands>(
    FusionBleCommandsImpl(),
  );

  //Register App Settings
  serviceLocator.registerSingleton<FusionPreferences>(FusionPreferences(sharedPreferencesHandler: serviceLocator<SharedPreferencesHandler>()));

  ///Register Project Manager
  serviceLocator.registerLazySingleton<ProjectCloudSyncManager>(
    () => ProjectCloudSyncManager(
      networkClient: serviceLocator<FusionNetworkClient>(),
      localProjectManager: serviceLocator<LocalProjectManager>(),
    ),
  );

  serviceLocator.registerLazySingleton<LocalProjectManager>(
    () => LocalProjectManager(
      sharedPreferencesHandler: serviceLocator<SharedPreferencesHandler>(),
    ),
  );

  serviceLocator.registerSingleton<FusionDeviceService>(
    FusionDeviceService(
      networkClient: serviceLocator<FusionNetworkClient>(),
    ),
  );

  serviceLocator.registerLazySingleton<FirmwareUpdateViewModel>(
    () => FirmwareUpdateViewModel(serviceLocator<FusionDeviceService>()),
  );

  serviceLocator.registerSingleton<FusionConfigSyncService>(
    FusionConfigSyncService(
      networkClient: serviceLocator<FusionNetworkClient>(),
    ),
  );

  serviceLocator.registerSingleton<DroConfigService>(
    DroConfigService(
      serviceLocator<FusionNetworkClient>(),
    ),
  );

  final ProjectManager pm = ProjectManager(
    projectCloudSyncManager: serviceLocator<ProjectCloudSyncManager>(),
    localProjectManager: serviceLocator<LocalProjectManager>(),
  );

  serviceLocator.registerSingleton<ProjectManager>(pm);

  serviceLocator.registerLazySingleton<ProjectViewModel>(() => ProjectViewModel(serviceLocator<ProjectManager>()));
  serviceLocator.registerLazySingleton<SessionViewModel>(
    () => SessionViewModel(),
  );
  serviceLocator.registerLazySingleton<AuthViewModel>(
    () => AuthViewModel(
      authService: serviceLocator<FusionAuthService>(),
      networkClient: serviceLocator<FusionNetworkClient>(),
      sessionViewModel: serviceLocator<SessionViewModel>(),
    ),
  );

  serviceLocator.registerLazySingleton<ProductQueryViewModel>(
    () => ProductQueryViewModel(
      networkClient: serviceLocator<FusionNetworkClient>(),
    ),
  );

  serviceLocator.registerLazySingleton<ProjectSyncService>(
    () => ProjectSyncService(
      networkClient: serviceLocator<FusionNetworkClient>(),
    ),
  );

  serviceLocator.registerLazySingleton<ProjectSyncViewModel>(
    () => ProjectSyncViewModel(
      serviceLocator<ProjectSyncService>(),
    ),
  );

  serviceLocator.registerLazySingleton<ProductQueryCubit>(() => ProductQueryCubit());

  serviceLocator.registerLazySingleton<MeterDataViewModel>(() => MeterDataViewModel());

  serviceLocator.registerLazySingleton<BlockDataViewmodel>(() => BlockDataViewmodel());

  serviceLocator.registerLazySingleton<ConfigSyncViewModel>(
    () => ConfigSyncViewModel(
      droConfigService: serviceLocator<DroConfigService>(),
      fusionConfigSyncService: serviceLocator<FusionConfigSyncService>(),
    ),
  );

  serviceLocator.registerLazySingleton<GuideShowCaseController>(() => GuideShowCaseController(globalNavigatorKey.currentContext!));

  // TODO: ALWAYS KEEP THIS AT THE END OF THE FILE
  await setupFusionLib(serviceLocator);
}
