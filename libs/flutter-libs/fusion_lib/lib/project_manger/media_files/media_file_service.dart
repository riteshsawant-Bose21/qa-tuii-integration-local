import 'dart:io';

import 'package:fusion_lib/fusion_lib.dart';

extension MediaFileService on ProjectService {
  List<MediaFileModel> getAllMediaFiles() {
    return mediaFiles.getAll();
  }

  MediaFileModel? getMediaFileById(String mediaId) {
    return mediaFiles.get(id);
  }

  Future<void> addMediaFile({required MediaFileModel mediaFile}) async {
    mediaFiles.add(mediaFile.id, mediaFile);
  }

  Future<void> removeMediaFileById(String mediaId) async {
    if (!mediaFiles.exists(mediaId)) {
      throw Exception("Media file with id $mediaId does not exist.");
    }
    mediaFiles.remove(mediaId);
  }
}
