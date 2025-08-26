import '../repositories/project_repository.dart';

class DeleteProjectUseCase {
  final ProjectRepository repository;

  DeleteProjectUseCase({required this.repository});

  Future<void> call(String projectName) async {
    await repository.deleteProject(projectName);
  }
}
