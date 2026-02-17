import 'package:fusion_lib/models/project_entities/controller.dart';

class FusionControllerSearchUseCase {
  List<FusionController> searchControllers(String query, List<FusionController> controllers) {
    final String lowerCaseQuery = query.toLowerCase();
    return controllers.where((FusionController controller) => controller.name.toLowerCase().contains(lowerCaseQuery)).toList();
  }
}
