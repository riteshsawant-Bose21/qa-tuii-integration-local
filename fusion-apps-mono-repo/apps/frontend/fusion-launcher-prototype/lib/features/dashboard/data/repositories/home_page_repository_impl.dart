import 'dart:typed_data';

import 'package:fusion_design_tool_prototype/core/models/response_callback.dart';
import 'package:fusion_design_tool_prototype/features/dashboard/data/datasources/home_page_datasource.dart';
import 'package:fusion_design_tool_prototype/features/dashboard/domain/entities/create_project_entity.dart';
import 'package:fusion_design_tool_prototype/features/dashboard/domain/entities/get_projects_entity.dart';

import '../../domain/entities/upload_file_entity.dart';
import '../../domain/repositories/home_page_repository.dart';

class HomePageRepositoryImpl implements HomePageRepository {
  final HomePageDatasource _homePageDatasource;

  HomePageRepositoryImpl(this._homePageDatasource);

  @override
  Future<ResponseCallback<CreateProjectEntity>> createProject({required String name, required String description, required String metadata}) {
    return _homePageDatasource.createProject(name: name, description: description, metadata: metadata);
  }

  @override
  Future<ResponseCallback<UploadFileEntity>> uploadFile({required String filename, required String filePath}) {
    return _homePageDatasource.uploadFile(filename: filename, filePath: filePath);
  }

  @override
  Future<ResponseCallback<List<GetProjectsEntity>>> getProjectsData() {
    return _homePageDatasource.getProjectsData();
  }

  @override
  Future<ResponseCallback<void>> deleteProject({required String projectId}) {
    return _homePageDatasource.deleteProject(projectId: projectId);
  }

  @override
  Future<ResponseCallback<Uint8List>> fetchFile({required String fileId}) {
    return _homePageDatasource.fetchFile(fileId: fileId);
  }

  @override
  Future<ResponseCallback<void>> updateProject({required String name, required String description, required String metadata, required String id}) {
    return _homePageDatasource.updateProject(name: name, description: description, metadata: metadata, id: id);
  }
}
