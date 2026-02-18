import 'package:fusion_web/core/usecases/usecase.dart';
import 'package:fusion_web/features/projects/domain/entities/project_entity.dart';
import 'package:fusion_web/features/projects/domain/repositories/projects_repository.dart';

class GetProjectByIdUseCase
    implements UseCase<ProjectEntity, GetProjectByIdParams> {

  final ProjectsRepository repository;

  const GetProjectByIdUseCase(this.repository);

  @override
  Future<ProjectEntity> call(GetProjectByIdParams params) {
    return repository.getProjectById(params.id);
  }
}

class GetProjectByIdParams {
  final String id;

  const GetProjectByIdParams(this.id);
}
