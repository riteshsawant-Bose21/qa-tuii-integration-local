import '../../../../core/models/project_entity.dart';
import '../repositories/project_repository.dart';

class LoadProjectUseCase {
  final ProjectRepository repository;

  LoadProjectUseCase({required this.repository});

  Future<ProjectEntity> call(String projectName) async {
    return await repository.loadProject(projectName);
  }
}
