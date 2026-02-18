import 'package:fusion_web/core/usecases/usecase.dart';
import 'package:fusion_web/features/projects/domain/entities/project_entity.dart';
import 'package:fusion_web/features/projects/domain/repositories/projects_repository.dart';

class UpdateProjectUseCase implements UseCase<ProjectEntity, ProjectEntity> {
  final ProjectsRepository repository;

  const UpdateProjectUseCase(this.repository);

  @override
  Future<ProjectEntity> call(ProjectEntity project) async {
    return await repository.updateProject(project);
  }
}