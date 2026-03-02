import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/dro/dro_input_model.dart';
import 'package:fusion_lib/project_manger/dro/dro_input_mapper_service.dart';

extension DroInputMapper on ProjectManager {
  DroInputModel getDroInputData() {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getDroInputData();
  }
}
