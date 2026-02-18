import 'package:fusion_web/core/usecases/usecase.dart';
import 'package:fusion_web/features/projects/domain/entities/project_entity.dart';
import 'package:fusion_web/features/projects/domain/repositories/projects_repository.dart';

class DeleteProjectUseCase implements UseCase<void, String> {
  final ProjectsRepository repository;

  const DeleteProjectUseCase(this.repository);

  @override
  Future<void> call(String id) async {
    return await repository.deleteProject(id);
  }
}