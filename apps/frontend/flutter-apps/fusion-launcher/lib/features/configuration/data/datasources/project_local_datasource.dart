import 'dart:io';

import '../../../../core/models/project_entity.dart';

abstract class ProjectLocalDataSource {
  Future<void> saveProject(ProjectEntity project);
  Future<ProjectEntity> loadProject(String projectName);
  Future<void> deleteProject(String projectName);
  Future<String> saveImageToProject(String projectName, String imagePath);
  Future<String> saveAssetImageToProject(String projectName, String assetPath);
  Future<File> getImageFromProject(String projectName, String imageName);
}
