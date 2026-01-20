import 'dart:typed_data';

import 'package:fusion_launcher/features/home/domain/entities/get_projects_entity.dart';
import 'package:fusion_lib/models/response_callback.dart';

import '../entities/create_project_entity.dart';
import '../entities/upload_file_entity.dart';

abstract class HomePageRepository {
  Future<ResponseCallback<CreateProjectEntity>> createProject({
    required String name,
    required String description,
    required String metadata,
  });

  Future<ResponseCallback<UploadFileEntity>> uploadFile({
    required String filename,
    required String filePath,
  });

  Future<ResponseCallback<List<GetProjectsEntity>>> getProjectsData();

  Future<ResponseCallback<void>> deleteProject({required String projectId});

  Future<ResponseCallback<void>> updateProject({
    required String name,
    required String id,
    required String description,
    required String metadata,
  });

  Future<ResponseCallback<Uint8List>> fetchFile({required String fileId});
}
