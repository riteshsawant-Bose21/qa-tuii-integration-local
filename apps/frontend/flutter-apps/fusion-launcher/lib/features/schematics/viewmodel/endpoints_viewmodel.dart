import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/device_listing_cubit.dart';
import 'package:fusion_lib/models/project_entities/endpoints.dart';

import '../usecase/search/endpoint_search_usecase.dart';

class SchematicEndpointsViewModel extends DeviceListingViewModel<FusionEndpoints> {
  SchematicEndpointsViewModel();

  @override
  List<FusionEndpoints> fetchDevices(String query) {
    return EndpointSearchUseCase().call(
      query,
      serviceLocator<ProjectViewModel>().fusionEndpoints,
    );
  }
}
