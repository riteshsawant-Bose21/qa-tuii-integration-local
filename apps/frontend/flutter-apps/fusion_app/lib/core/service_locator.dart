import 'package:fusion_lib/fusion_lib.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fusion_app/core/models/user_profile_model.dart';
import 'package:fusion_app/core/services/user_profile_manager.dart';
import 'package:fusion_app/features/authentication/viewmodel/session_view_model.dart';
import 'package:fusion_app/features/scanner/view_model/fusion_qr_service.dart';
import 'package:fusion_app/features/scanner/view_model/qr_scanner_view_model.dart';
import 'package:fusion_lib/di/service_locator.dart';
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
  try {

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      serviceLocator.registerSingleton<SharedPreferences>(prefs);


      serviceLocator.registerSingleton<SharedPreferencesHandler>(
          SharedPreferencesHandler.getInstance(
              serviceLocator<SharedPreferences>()));

      serviceLocator.registerLazySingleton<FlutterSecureStorage>(
            () =>
        const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        ),
      );

      serviceLocator.registerLazySingleton<FusionSecureStorage>(
            () =>
            FusionSecureStorageImpl(serviceLocator<FlutterSecureStorage>()),
      );


    serviceLocator.registerLazySingleton<WebSocketService>(
          () => WebSocketService(),
    );

    serviceLocator.registerSingleton<DioClient>(
      DioClient(dioInstance: Dio(), interceptors: <Interceptor>[
        //AppInterceptors()
      ]),
    );

   try {
     //register Telemetry manager
     serviceLocator.registerLazySingleton<TelemetryData>(() => TelemetryData());
   }catch(e){
      print("Error registering TelemetryData: $e");
   }

   try {
     serviceLocator.registerLazySingleton<FusionAuthService>(
           () =>
           FusionAuthService(
             domain: AppConfig.auth0Domain,
             clientId: AppConfig.auth0ClientId,
             secureStorage: serviceLocator<FusionSecureStorage>(),
             authScheme: AppConfig.auth0Schema,
             webRedirectUrl: AppConfig.auth0RedirectUri,
             nativeRedirectUrl: AppConfig.auth0NativeRedirectUri,
           ),
     );
   }catch(e) {
     print("Error registering FusionAuthService: $e");
   }
    try {
      serviceLocator.registerLazySingleton<FusionQRService>(
            () =>
            FusionQRService(
              networkClient: serviceLocator<FusionNetworkClient>(),
            ),
      );
    }catch(e){
      print("Error registering FusionQRService: $e");
    }

    serviceLocator.registerLazySingleton<FusionVirtualControllerService>(
          () =>
          FusionVirtualControllerService(
            networkClient: serviceLocator<FusionNetworkClient>(),
          ),
    );
    try {
      serviceLocator.registerSingleton<FusionNetworkClient>(
        FusionNetworkClient(
            httpClient: serviceLocator<DioClient>(),
            sharedPreferencesHandler: serviceLocator<
                SharedPreferencesHandler>(),
            telemetryData: serviceLocator<TelemetryData>(),
            fusionAuthService: serviceLocator<FusionAuthService>(),
            secureStorageService: serviceLocator<FusionSecureStorage>(),
            apiBaseUrl: AppConfig.awsApiBaseUrl,
            webSocketService: serviceLocator<WebSocketService>()
        ),
      );
    }catch(e){
      print("Error registering FusionNetworkClient: $e");
    }

    // final UserProfile initialUserProfile = UserProfile(
    //   personalInfo: PersonalInfo(
    //     name: "",
    //     organization: "",
    //     jobTitle: "",
    //     phone: "",
    //   ),
    //
    //   security: Security(
    //     username: "",
    //     password: "",
    //     isTwoFactorEnabled: false,
    //     enableEmailNotifications: false,
    //     enableSMSNotifications: false,
    //   ),
    //   address: Address(
    //     addressLine1: "",
    //     addressLine2: "",
    //     city: "",
    //     state: "",
    //     zipCode: "",
    //     country: "",
    //     timezone: "",
    //   ),
    //   measurementUnit: "",
    //   currency: "USD",
    //   language: "English (US)",
    //   notifications: Notifications(productUpdates: false,
    //       projectActivity: false,
    //       trainingAndResources: false),
    //   location: '',
    // );
    //
    // /// Registering the ProjectListManager with the initial project
    //
    // final UserProfileManager upm = UserProfileManager(initialUserProfile);
    // serviceLocator.registerSingleton<UserProfileManager>(upm);

    //Register App Settings

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

    serviceLocator.registerSingleton<FusionPreferences>(FusionPreferences(
        sharedPreferencesHandler: serviceLocator<SharedPreferencesHandler>()));

      final ProjectManager pm = ProjectManager(
        projectCloudSyncManager: serviceLocator<ProjectCloudSyncManager>(),
        localProjectManager: serviceLocator<LocalProjectManager>(),
      );

      serviceLocator.registerSingleton<ProjectManager>(pm);


      serviceLocator.registerLazySingleton<ProjectViewModel>(() => ProjectViewModel(serviceLocator<ProjectManager>()));


    try {
      serviceLocator.registerLazySingleton<SessionViewModel>(
            () => SessionViewModel(),
      );
    }catch(e){
      print("Error registering SessionViewModel: $e");
    }
    try {
      serviceLocator.registerLazySingleton<AuthViewModel>(
            () =>
            AuthViewModel(
              authService: serviceLocator<FusionAuthService>(),
              networkClient: serviceLocator<FusionNetworkClient>(),
              sessionViewModel: serviceLocator<SessionViewModel>(),
            ),
      );
    }catch(e){
      print("Error registering AuthViewModel: $e");
    }

    serviceLocator.registerLazySingleton<QrScannerViewModel>(
          () =>
          QrScannerViewModel(
            qrService: serviceLocator<FusionQRService>(),
            networkClient: serviceLocator<FusionNetworkClient>(),
          ),
    );


    serviceLocator.registerLazySingleton<VirtualControllerViewModel>(
          () =>
          VirtualControllerViewModel(
            service: serviceLocator<FusionVirtualControllerService>(),
          ),
    );

    // TODO: ALWAYS KEEP THIS AT THE END OF THE FILE
    await setupFusionLib(serviceLocator);
  }catch(e){
    print(e);
  }
}
