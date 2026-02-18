import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/device_listing_cubit.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

import '../usecase/search/fusion_controller_search_usecase.dart';

class SchematicFusionControllerViewModel extends DeviceListingViewModel<FusionController> {
  @override
  List<FusionController> fetchDevices(String query) {
    return FusionControllerSearchUseCase().call(
      query,
      serviceLocator<ProjectViewModel>().fusionControllers,
    );
  }
}
