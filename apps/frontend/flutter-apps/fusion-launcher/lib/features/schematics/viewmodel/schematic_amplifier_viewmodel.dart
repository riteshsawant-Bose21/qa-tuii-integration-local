import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/device_listing_cubit.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../usecase/search/amplifier_search_usecase.dart';

class SchematicAmplifiersViewModel extends DeviceListingViewModel<Amplifier> {
  @override
  List<Amplifier> fetchDevices(String query) {
    return AmplifierSearchUseCase().call(
      query,
      serviceLocator<ProjectViewModel>().amplifiers,
    );
  }
}
