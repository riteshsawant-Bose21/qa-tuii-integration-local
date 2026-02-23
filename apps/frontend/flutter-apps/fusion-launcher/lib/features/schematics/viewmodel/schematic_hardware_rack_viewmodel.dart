import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/schematics/entity/schematic_hardware_component.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/device_listing_cubit.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../usecase/schematic_hardware_transform_usecase.dart';
import '../usecase/search/network_switch_search_usecase.dart';

class SchematicHardwareRacksViewModel extends DeviceListingViewModel<SchematicHardwareComponent<HardwareRack>> {
  @override
  List<SchematicHardwareComponent<HardwareRack>> fetchDevices(String query) {
    final List<HardwareRack> result = HardwareRackSearchUseCase().call(
      query,
      serviceLocator<ProjectViewModel>().hardwareRacks,
    );
    return SchematicHardwareTransformUseCase<HardwareRack>().forModels(result);
  }
}
