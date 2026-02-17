import 'package:fusion_lib/models/project_entities/endpoints.dart';

class EndpointSearchUseCase {
  List<FusionEndpoints> searchEndpoints(String query, List<FusionEndpoints> sources) {
    final String lowerCaseQuery = query.toLowerCase();
    return sources.where((FusionEndpoints source) => source.name.toLowerCase().contains(lowerCaseQuery)).toList();
  }
}
