import 'package:fusion_lib/fusion_lib.dart';

class FusionDspSearchUseCase {
  List<FusionDsp> searchDSP(String query, List<FusionDsp> sources) {
    final String lowerCaseQuery = query.toLowerCase();
    return sources.where((FusionDsp source) => source.name.toLowerCase().contains(lowerCaseQuery)).toList();
  }
}
