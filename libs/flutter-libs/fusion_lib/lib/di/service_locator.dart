import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fusion_utils/app_settings.dart';
import '../fusion_utils/image_loader_service.dart';
import '../fusion_utils/shared_preference_handler.dart';
import '../fusion_utils/telemetry_data.dart';

final GetIt fusionLibLocator = GetIt.instance;

Future<void> setupFusionLibServiceLocator() async {
  // Registering SharedPreferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  fusionLibLocator.registerSingleton<SharedPreferences>(prefs);

  fusionLibLocator.registerSingleton<SharedPreferencesHandler>(SharedPreferencesHandler.getInstance());

  //Register App Settings
  fusionLibLocator.registerSingleton<FusionPreferences>(FusionPreferences());

  //Register Telemetry manager
  fusionLibLocator.registerLazySingleton<TelemetryData>(() => TelemetryData());

  // Register ImageLoaderService
  fusionLibLocator.registerSingleton<ImageLoaderService>(ImageLoaderService());
}
