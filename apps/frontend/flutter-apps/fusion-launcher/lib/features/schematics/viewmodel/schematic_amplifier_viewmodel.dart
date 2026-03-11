import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/schematics/entity/schematic_hardware_component.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/device_listing_cubit.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../usecase/schematic_hardware_transform_usecase.dart';
import '../usecase/search/amplifier_search_usecase.dart';

class SchematicAmplifiersViewModel extends DeviceListingViewModel<SchematicHardwareComponent<Amplifier>> {
  @override
  List<SchematicHardwareComponent<Amplifier>> fetchDevices(String query) {
    final List<Amplifier> result = AmplifierSearchUseCase().call(
      query,
      serviceLocator<ProjectViewModel>().amplifiers,
    );
    return SchematicHardwareTransformUseCase<Amplifier>().forModels(result);
  }
}
