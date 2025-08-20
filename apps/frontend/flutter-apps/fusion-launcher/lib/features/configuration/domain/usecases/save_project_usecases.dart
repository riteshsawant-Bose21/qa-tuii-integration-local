import '../../../../core/models/project_entity.dart';
import '../repositories/project_repository.dart';

class SaveProjectUseCase {
  final ProjectRepository repository;

  SaveProjectUseCase({required this.repository});

  Future<void> call(ProjectEntity project) async {
    await repository.saveProject(project);
  }
}
