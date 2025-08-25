import 'package:get_it/get_it.dart';

import '../fusion_utils/image_loader_service.dart';

late final GetIt fusionLibLocator;
Future<void> setupFusionLib(GetIt serviceLocator) async {
  fusionLibLocator = serviceLocator;

  // Register ImageLoaderService
  fusionLibLocator.registerSingleton<ImageLoaderService>(ImageLoaderService());
}
