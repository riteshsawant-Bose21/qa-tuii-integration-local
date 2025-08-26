import 'package:fusion_lib/models/project_entities/project_data.dart';

import '../repositories/project_repository.dart';

class LoadProjectUseCase {
  final ProjectRepository repository;

  LoadProjectUseCase({required this.repository});

  Future<ProjectData> call(String projectName) async {
    return await repository.loadProject(projectName);
  }
}
