
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fusion_app/core/models/user_profile_model.dart';
import 'package:fusion_app/core/router/navigation_observer.dart';
import 'package:fusion_app/core/services/user_profile_manager.dart';
import 'package:fusion_app/features/authentication/viewmodel/session_view_model.dart';
// import 'package:fusion_app/features/projects/view_model/project_sync_view_model.dart';
//import 'package:fusion_app/features/shared/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/di/service_locator.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_networking/network/rest_client/dio_client.dart';
import 'package:fusion_lib/service/auth/fusion_auth_service.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/authentication/viewmodel/auth_view_model.dart';
import '../features/landing/viewmodel/project_view_model.dart';
import 'config/app_config.dart';
final GetIt serviceLocator = GetIt.instance;

Future<void> setupServiceLocator() async {
  //final Map<String, dynamic> jsonMap = jsonDecode(algoMetadataJSON);
  //final FusionAlgorithmsConfig fusionAlgorithmsConfig = FusionAlgorithmsConfig.fromJson(jsonMap);
  //serviceLocator.registerSingleton<FusionAlgorithmsConfig>(fusionAlgorithmsConfig);

  final SharedPreferences prefs = await SharedPreferences.getInstance();
   serviceLocator.registerSingleton<SharedPreferences>(prefs);
  serviceLocator.registerSingleton<SharedPreferencesHandler>(SharedPreferencesHandler.getInstance(serviceLocator<SharedPreferences>()));

  serviceLocator.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  serviceLocator.registerLazySingleton<FusionSecureStorage>(
    () => FusionSecureStorageImpl(serviceLocator<FlutterSecureStorage>()),
  );

  serviceLocator.registerSingleton<DioClient>(
    DioClient(dioInstance: Dio(), interceptors: <Interceptor>[
      //AppInterceptors()
    ]),
  );
  //
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
  //
  serviceLocator.registerSingleton<FusionNetworkClient>(
    FusionNetworkClient(
      httpClient: serviceLocator<DioClient>(),
      sharedPreferencesHandler: serviceLocator<SharedPreferencesHandler>(),
      telemetryData: serviceLocator<TelemetryData>(),
      fusionAuthService: serviceLocator<FusionAuthService>(),
      secureStorageService: serviceLocator<FusionSecureStorage>(),
      apiBaseUrl: AppConfig.awsApiBaseUrl,
    ),
  );
  //
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
  // serviceLocator.registerLazySingleton<PanelDataSource>(() => PanelDataSourceImpl());
  //
  // serviceLocator.registerLazySingleton<PanelRepository>(() => PanelRepositoryImpl());
  // serviceLocator.registerLazySingleton<PanelBloc>(() => PanelBloc());
  //
  // serviceLocator.registerLazySingleton<GetPanelDataUseCase>(() => GetPanelDataUseCase());
  // serviceLocator.registerLazySingleton<SendWidgetDataUseCase>(() => SendWidgetDataUseCase());
  // serviceLocator.registerLazySingleton<InitializePanelUseCase>(() => InitializePanelUseCase());
  // serviceLocator.registerLazySingleton<DisposePanelUseCase>(() => DisposePanelUseCase());
  // serviceLocator.registerLazySingleton<GetPanelStreamUseCase>(() => GetPanelStreamUseCase());
  // serviceLocator.registerLazySingleton<ResetFusionUseCase>(() => ResetFusionUseCase());
  // serviceLocator.registerLazySingleton<GetPanelEntityUseCase>(() => GetPanelEntityUseCase());
  // serviceLocator.registerLazySingleton<CreateProjectUseCase>(() => CreateProjectUseCase());
  // serviceLocator.registerLazySingleton<UploadFileUseCase>(() => UploadFileUseCase());
  // serviceLocator.registerLazySingleton<GetProjectsDataUseCase>(() => GetProjectsDataUseCase());
  // serviceLocator.registerLazySingleton<DeleteProjectUseCase>(() => DeleteProjectUseCase());
  // serviceLocator.registerLazySingleton<FetchFileUsecase>(() => FetchFileUsecase());
  // serviceLocator.registerLazySingleton<UpdateProjectUsecase>(() => UpdateProjectUsecase());

  /// Registering the ProjectListManager with the initial project

  final UserProfileManager upm = UserProfileManager(initialUserProfile);
  serviceLocator.registerSingleton<UserProfileManager>(upm);

  // serviceLocator.registerSingleton<ImageLoaderService>(
  //   ImageLoaderService(),
  // );

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

  serviceLocator.registerLazySingleton<ProjectSyncService>(
    () => ProjectSyncService(
      networkClient: serviceLocator<FusionNetworkClient>(),
    ),
  );
  //
  // serviceLocator.registerLazySingleton<ProjectSyncViewModel>(
  //   () => ProjectSyncViewModel(
  //     serviceLocator<ProjectSyncService>(),
  //   ),
  // );
  //
  // serviceLocator.registerLazySingleton<ProductQueryCubit>(() => ProductQueryCubit());
  serviceLocator.registerLazySingleton<GuideShowCaseController>(() => GuideShowCaseController(globalNavigatorKey.currentContext!));

  // TODO: ALWAYS KEEP THIS AT THE END OF THE FILE
  await setupFusionLib(serviceLocator);
}
