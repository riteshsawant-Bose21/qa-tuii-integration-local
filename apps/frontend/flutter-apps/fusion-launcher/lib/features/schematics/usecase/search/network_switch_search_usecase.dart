import 'package:fusion_lib/fusion_lib.dart';

class HardwareRackSearchUseCase {
  List<HardwareRack> call(String query, List<HardwareRack> sources) {
    final String lowerCaseQuery = query.toLowerCase();
    return sources.where((HardwareRack source) => source.name.toLowerCase().contains(lowerCaseQuery)).toList();
  }
}
