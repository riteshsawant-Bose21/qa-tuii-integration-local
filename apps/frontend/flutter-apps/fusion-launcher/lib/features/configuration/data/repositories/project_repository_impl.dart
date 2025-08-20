import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../../../core/models/project_entity.dart';
import '../../../../core/models/project_metadata_model.dart';
import '../../../../core/utils/helper.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_local_datasource.dart';
import '../datasources/project_remote_datasouce.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectLocalDataSource localDataSource;
  final ProjectRemoteDataSource remoteDataSource;

  ProjectRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<void> saveProject(ProjectEntity project) async {
    try {
      await localDataSource.saveProject(project);
    } catch (e) {
      throw Exception('Failed to save project: $e');
    }
  }

  @override
  Future<ProjectEntity> loadProject(String projectName) async {
    try {
      return await localDataSource.loadProject(projectName);
    } catch (e) {
      throw Exception('Failed to load project: $e');
    }
  }

  @override
  Future<void> deleteProject(String projectName) async {
    try {
      await localDataSource.deleteProject(projectName);
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }

  @override
  Future<String> saveImageToProject(String projectName, String imagePath) async {
    try {
      return await localDataSource.saveImageToProject(projectName, imagePath);
    } catch (e) {
      throw Exception('Failed to save image: $e');
    }
  }

  @override
  Future<(bool success, String message)> uploadToCloud(ProjectEntity project) async {
    try {
      // Create zip file logic here (similar to original implementation)
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory fusionDir = Directory('${appDocDir.path}/FusionProject/${project.name}');

      // Update project with current timestamp
      final ProjectEntity updatedProject = project.copyWith(updatedAt: DateTime.now());
      await saveProject(updatedProject);

      // Create zip file
      final File zipFile = await Helper.zipFusionProjectFolder(fusionDir);

      // Upload zip file
      final String? zipFileId = await remoteDataSource.uploadFile(zipFile.path);

      if (zipFileId == null) {
        if (await zipFile.exists()) await zipFile.delete();
        return (false, 'Failed to upload zip file');
      }

      // Upload thumbnail if exists
      String? thumbnailFileId;
      if (project.currentFloor.floorPlan.imagePath.trim().isNotEmpty) {
        thumbnailFileId = await remoteDataSource.uploadFile(
          '${appDocDir.path}/${project.currentFloor.floorPlan.imagePath}',
        );
      }

      // Create metadata
      final ProjectMetadataModel metadata = ProjectMetadataModel(
        fileId: zipFileId,
        thumbnailUrl: thumbnailFileId ?? "",
        projectName: project.projectName,
      );

      // Update project in cloud
      await remoteDataSource.updateProject(
        id: project.cloudId,
        name: project.name,
        description: project.name,
        metadata: metadata,
      );

      // Clean up
      if (await zipFile.exists()) await zipFile.delete();

      return (true, 'Project uploaded successfully');
    } catch (e) {
      return (false, 'Upload failed: $e');
    }
  }

  @override
  Future<Uint8List?> downloadFromCloud(String fileId) async {
    try {
      return await remoteDataSource.downloadFile(fileId);
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }
}
