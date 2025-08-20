import '../../../../core/models/project_entity.dart';
import '../repositories/project_repository.dart';

class UploadProjectUseCase {
  final ProjectRepository repository;

  UploadProjectUseCase({required this.repository});

  Future<(bool success, String message)> call(ProjectEntity project) async {
    return await repository.uploadToCloud(project);
  }
}
