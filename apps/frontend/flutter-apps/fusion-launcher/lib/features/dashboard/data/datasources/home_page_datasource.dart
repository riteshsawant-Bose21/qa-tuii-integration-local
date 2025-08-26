import 'dart:typed_data';

import 'package:fusion_launcher/features/dashboard/domain/entities/get_projects_entity.dart';
import 'package:fusion_launcher/features/dashboard/domain/entities/upload_file_entity.dart';
import 'package:fusion_lib/models/response_callback.dart';

import '../../domain/entities/create_project_entity.dart';

abstract class HomePageDatasource {
  /// Creates a new project with the given [name], [description], and [metadata].
  Future<ResponseCallback<CreateProjectEntity>> createProject({
    required String name,
    required String description,
    required String metadata,
  });

  /// Uploads a file to the server for the specified project.
  Future<ResponseCallback<UploadFileEntity>> uploadFile({
    required String filename,
    required String filePath,
  });

  /// Fetches a file by its [fileId].
  Future<ResponseCallback<Uint8List>> fetchFile({required String fileId});

  /// Retrieves a list of projects.
  Future<ResponseCallback<List<GetProjectsEntity>>> getProjectsData();

  /// Deletes a project by its [projectId].

  Future<ResponseCallback<void>> deleteProject({required String projectId});

  /// update existing project with the given [name], [description], and [metadata].
  Future<ResponseCallback<void>> updateProject({
    required String name,
    required String id,
    required String description,
    required String metadata,
  });
}
