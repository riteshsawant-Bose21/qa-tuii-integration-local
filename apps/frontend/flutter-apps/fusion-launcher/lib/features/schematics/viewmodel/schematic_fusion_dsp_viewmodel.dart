import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/device_listing_cubit.dart';
import 'package:fusion_lib/models/project_entities/fusion_dsp.dart';

import '../usecase/search/fusion_device_search_usecase.dart';

class SchematicFusionDeviceViewModel extends DeviceListingViewModel<FusionDsp> {
  @override
  List<FusionDsp> fetchDevices(String query) {
    return FusionDspSearchUseCase().call(
      query,
      serviceLocator<ProjectViewModel>().fusionDsps,
    );
  }
}
