import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/device_listing_cubit.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../usecase/source_search_usecase.dart';

class SchematicSourcesViewModel extends DeviceListingViewModel<Source> {
  SchematicSourcesViewModel();

  @override
  List<Source> fetchDevices(String query) {
    return SourceSearchUseCase().searchSources(
      query,
      serviceLocator<ProjectViewModel>().sources,
    );
  }
}
