import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/schematics/usecase/search/zone_search_usecase.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/device_listing_cubit.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SchematicZoneViewModel extends DeviceListingViewModel<Zone> {
  @override
  List<Zone> fetchDevices(String query) {
    return ZoneSearchUseCase().call(
      query,
      serviceLocator<ProjectViewModel>().zones,
    );
  }
}
