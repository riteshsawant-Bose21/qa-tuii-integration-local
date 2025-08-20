import 'dart:typed_data';

import '../../../../core/models/project_metadata_model.dart';

abstract class ProjectRemoteDataSource {
  Future<String?> uploadFile(String filePath);
  Future<Uint8List?> downloadFile(String fileId);
  Future<void> updateProject({
    required String id,
    required String name,
    required String description,
    required ProjectMetadataModel metadata,
  });
}
