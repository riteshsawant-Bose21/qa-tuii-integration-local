import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fusion_utils/app_settings.dart';
import '../fusion_utils/image_loader_service.dart';
import '../fusion_utils/shared_preference_handler.dart';
import '../fusion_utils/telemetry_data.dart';

Future<void> setupFusionLib(GetIt serviceLocator) async {

  // Register ImageLoaderService
  fusionLibLocator.registerSingleton<ImageLoaderService>(ImageLoaderService());
}
