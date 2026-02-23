import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/schematics/entity/schematic_hardware_component.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/device_listing_cubit.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

import '../usecase/schematic_hardware_transform_usecase.dart';
import '../usecase/search/fusion_controller_search_usecase.dart';

class SchematicFusionControllerViewModel extends DeviceListingViewModel<SchematicHardwareComponent<FusionController>> {
  @override
  List<SchematicHardwareComponent<FusionController>> fetchDevices(String query) {
    final List<FusionController> result = FusionControllerSearchUseCase().call(
      query,
      serviceLocator<ProjectViewModel>().fusionControllers,
    );
    return SchematicHardwareTransformUseCase<FusionController>().forModels(result);
  }
}
