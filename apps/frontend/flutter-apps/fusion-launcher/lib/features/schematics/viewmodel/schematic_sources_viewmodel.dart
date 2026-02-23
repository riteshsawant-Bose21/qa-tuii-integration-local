import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/schematics/entity/schematic_hardware_component.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/device_listing_cubit.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../usecase/schematic_hardware_transform_usecase.dart';
import '../usecase/search/source_search_usecase.dart';

class SchematicSourcesViewModel extends DeviceListingViewModel<SchematicHardwareComponent<Source>> {
  @override
  List<SchematicHardwareComponent<Source>> fetchDevices(String query) {
    final List<Source> result = SourceSearchUseCase().call(
      query,
      serviceLocator<ProjectViewModel>().sources,
    );
    return SchematicHardwareTransformUseCase<Source>().forModels(result);
  }
}
