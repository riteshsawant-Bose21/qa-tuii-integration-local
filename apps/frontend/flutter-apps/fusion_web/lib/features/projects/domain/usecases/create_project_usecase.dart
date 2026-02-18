import 'package:fusion_web/core/usecases/usecase.dart';
import 'package:fusion_web/features/projects/domain/entities/project_entity.dart';
import 'package:fusion_web/features/projects/domain/repositories/projects_repository.dart';

class CreateProjectUseCase implements UseCase<ProjectEntity, ProjectEntity> {
  final ProjectsRepository repository;

  const CreateProjectUseCase(this.repository);

  @override
  Future<ProjectEntity> call(ProjectEntity project) {
    return repository.createProject(project);
  }
}
