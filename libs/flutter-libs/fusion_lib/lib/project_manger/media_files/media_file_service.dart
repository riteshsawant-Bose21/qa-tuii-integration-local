import 'dart:io';

import 'package:fusion_lib/fusion_lib.dart';

extension MediaFileService on ProjectService {
  List<MediaFileModel> getAllMediaFiles() {
    return mediaFiles.getAll();
  }

  MediaFileModel? getMediaFileById(String mediaId) {
    return mediaFiles.get(mediaId);
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

  void updateMediaFile({required MediaFileModel mediaFile}) {
    if (!mediaFiles.exists(mediaFile.id)) {
      throw Exception("Media file with id ${mediaFile.id} does not exist.");
    }
    mediaFiles.add(mediaFile.id, mediaFile);
  }
}
