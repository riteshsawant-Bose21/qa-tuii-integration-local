import 'package:fusion_lib/models/project_entities/project_data.dart';

import '../repositories/project_repository.dart';

class SaveProjectUseCase {
  final ProjectRepository repository;

  SaveProjectUseCase({required this.repository});

  Future<void> call(ProjectData project) async {
    await repository.saveProject(project);
  }
}
