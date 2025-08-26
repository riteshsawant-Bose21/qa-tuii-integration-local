import '../repositories/project_repository.dart';

class SaveImageToProjectUseCase {
  final ProjectRepository repository;

  SaveImageToProjectUseCase({required this.repository});

  Future<String> call(String projectName, String imagePath) async {
    return await repository.saveImageToProject(projectName, imagePath);
  }
}
