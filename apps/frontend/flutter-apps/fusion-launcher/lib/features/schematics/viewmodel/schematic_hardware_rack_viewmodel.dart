import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/device_listing_cubit.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../usecase/search/network_switch_search_usecase.dart';

class SchematicHardwareRacksViewModel extends DeviceListingViewModel<HardwareRack> {
  @override
  List<HardwareRack> fetchDevices(String query) {
    return HardwareRackSearchUseCase().call(
      query,
      serviceLocator<ProjectViewModel>().hardwareRacks,
    );
  }
}
