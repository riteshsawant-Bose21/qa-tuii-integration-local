import 'dart:io';

import 'package:fusion_lib/fusion_lib.dart';

extension MediaFileManager on ProjectManager {
  Future<void> addMediaFile({required File mediaFile, String? fileName}) async {
    // Ensure projectService is not null
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }

    fileName ??= mediaFile.path.split(Platform.pathSeparator).last;

    String filePath = await localProjectManager.saveMediaFileToProject(mediaFile: mediaFile, projectId: projectService!.id, fileName: fileName);

    MediaFileModel mediaFileModel = MediaFileModel(
      path: filePath,
      name: fileName,
      date: DateTime.now().toUtc(),
      size: await mediaFile.length(),
      length: await FusionUtils().getMediaDuration(mediaFile),
    );

    // Call the addMediaFile method from ProjectService
    await projectService!.addMediaFile(mediaFile: mediaFileModel);
  }

  List<MediaFileModel> getAllMediaFiles() {
    // Ensure projectService is not null
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }

    return projectService!.getAllMediaFiles();
  }

  Future<void> removeMediaFileById(String mediaId) async {
    // Ensure projectService is not null
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }

    final MediaFileModel? mediaFile = projectService!.getMediaFileById(mediaId);
    if (mediaFile == null) {
      throw Exception("Media file with id $mediaId does not exist.");
    }

    await localProjectManager.deleteMediaFileFromProject(fileName: mediaFile.name, projectId: projectService!.id);

    await projectService!.removeMediaFileById(mediaId);
  }

  MediaFileModel? getMediaFileById(String mediaId) {
    // Ensure projectService is not null
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }

    return projectService!.getMediaFileById(mediaId);
  }

  Future<List<File>> getAllMediaFilesInProject() async {
    // Ensure projectService is not null
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }

    return await localProjectManager.getAllMediaFilesFromProject(projectId: projectService!.id);
  }
}
