import 'dart:io';

import 'package:fusion_lib/models/project_entities/project_data.dart';

abstract class ProjectLocalDataSource {
  Future<void> saveProject(ProjectData project);
  Future<ProjectData> loadProject(String projectName);
  Future<void> deleteProject(String projectName);
  Future<String> saveImageToProject(String projectName, String imagePath);
  Future<String> saveAssetImageToProject(String projectName, String assetPath);
  Future<File> getImageFromProject(String projectName, String imageName);
}
