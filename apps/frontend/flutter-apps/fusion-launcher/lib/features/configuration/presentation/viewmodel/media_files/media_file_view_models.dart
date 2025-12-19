import 'dart:io';

import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension MediaFileViewModels on ProjectViewModel {
  Future<void> addMediaFile({required File file, String? fileName, bool autoSave = true}) async {
    if (autoSave) {
      recordSnapshot();
    }
    await projectManager.addMediaFile(mediaFile: file, fileName: fileName);

    if (autoSave) {
      await saveProject();
    }
  }

  List<MediaFileModel> getAllMediaFiles() {
    return projectManager.getAllMediaFiles();
  }

  Future<void> removeMediaFileById(String mediaId, {bool autoSave = true}) async {
    if (autoSave) {
      recordSnapshot();
    }
    await projectManager.removeMediaFileById(mediaId);

    if (autoSave) {
      await saveProject();
    }
  }

  MediaFileModel? getMediaFileById(String mediaId) {
    try {
      return projectManager.getMediaFileById(mediaId);
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Error getting media file by id: $ex");
      return null;
    }
  }

  Future<List<File>> getAllMediaFilesInProject() async {
    try {
      return await projectManager.getAllMediaFilesInProject();
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Error getting all media files in project: $ex");
      return <File>[];
    }
  }
}
