import 'dart:typed_data';

import 'package:fusion_lib/models/project_entities/project_data.dart';

abstract class ProjectRepository {
  Future<void> saveProject(ProjectData project);
  Future<ProjectData> loadProject(String projectName);
  Future<void> deleteProject(String projectName);
  Future<String> saveImageToProject(String projectName, String imagePath);
  Future<(bool success, String message)> uploadToCloud(ProjectData project);
  Future<Uint8List?> downloadFromCloud(String fileId);
}
