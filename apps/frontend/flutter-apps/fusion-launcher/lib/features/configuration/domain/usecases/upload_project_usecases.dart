import 'package:fusion_lib/models/project_entities/project_data.dart';

import '../repositories/project_repository.dart';

class UploadProjectUseCase {
  final ProjectRepository repository;

  UploadProjectUseCase({required this.repository});

  Future<(bool success, String message)> call(ProjectData project) async {
    return await repository.uploadToCloud(project);
  }
}
