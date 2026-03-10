import 'package:fusion_lib/fusion_lib.dart';

class NetworkSwitchSearchUseCase {
  List<NetworkSwitch> call(String query, List<NetworkSwitch> sources) {
    final String lowerCaseQuery = query.toLowerCase();
    return sources.where((NetworkSwitch source) => source.name.toLowerCase().contains(lowerCaseQuery)).toList();
  }
}
