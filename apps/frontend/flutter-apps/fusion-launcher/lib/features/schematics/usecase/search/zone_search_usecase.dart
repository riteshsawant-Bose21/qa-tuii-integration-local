import 'package:fusion_lib/fusion_lib.dart';

class ZoneSearchUseCase {
  List<Zone> call(String query, List<Zone> zones) {
    final String lowerCaseQuery = query.toLowerCase();
    return zones.where((Zone zone) => zone.name.toLowerCase().contains(lowerCaseQuery)).toList();
  }
}
