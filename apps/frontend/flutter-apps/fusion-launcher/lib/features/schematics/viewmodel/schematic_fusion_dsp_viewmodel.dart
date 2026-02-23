import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/schematics/entity/schematic_hardware_component.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/device_listing_cubit.dart';
import 'package:fusion_lib/models/project_entities/fusion_dsp.dart';

import '../usecase/schematic_hardware_transform_usecase.dart';
import '../usecase/search/fusion_device_search_usecase.dart';

class SchematicFusionDeviceViewModel extends DeviceListingViewModel<SchematicHardwareComponent<FusionDsp>> {
  @override
  List<SchematicHardwareComponent<FusionDsp>> fetchDevices(String query) {
    final List<FusionDsp> result = FusionDspSearchUseCase().call(
      query,
      serviceLocator<ProjectViewModel>().fusionDsps,
    );
    return SchematicHardwareTransformUseCase<FusionDsp>().forModels(result);
  }
}
