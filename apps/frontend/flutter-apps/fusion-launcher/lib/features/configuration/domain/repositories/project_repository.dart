import 'dart:typed_data';

import '../../../../core/models/project_entity.dart';

abstract class ProjectRepository {
  Future<void> saveProject(ProjectEntity project);
  Future<ProjectEntity> loadProject(String projectName);
  Future<void> deleteProject(String projectName);
  Future<String> saveImageToProject(String projectName, String imagePath);
  Future<(bool success, String message)> uploadToCloud(ProjectEntity project);
  Future<Uint8List?> downloadFromCloud(String fileId);
}
