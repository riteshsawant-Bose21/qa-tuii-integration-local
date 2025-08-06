import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fusion_design_tool_prototype/core/models/response_callback.dart';
import 'package:fusion_design_tool_prototype/features/dashboard/data/datasources/home_page_datasource.dart';
import 'package:fusion_design_tool_prototype/features/dashboard/data/models/get_projects_response_dto.dart';
import 'package:fusion_design_tool_prototype/features/dashboard/data/models/upload_file_response_dto.dart';
import 'package:fusion_design_tool_prototype/features/dashboard/domain/entities/get_projects_entity.dart';

import '../../../../core/network_clients/fusion_network_client.dart';
import '../../domain/entities/create_project_entity.dart';
import '../../domain/entities/upload_file_entity.dart';
import '../models/create_project_dto.dart';

class HomePageDatasourceImpl implements HomePageDatasource {
  final FusionNetworkClient _fusionNetworkClient;
  HomePageDatasourceImpl(this._fusionNetworkClient);

  /// Creates a new project with the given parameters.
  @override
  Future<ResponseCallback<CreateProjectEntity>> createProject({
    required String name,
    required String description,
    required String metadata,
  }) async {
    try {
      final Map<String, dynamic> formData = <String, dynamic>{
        'name': name,
        'description': description,
        'metadata': metadata,
      };

      final ResponseCallback<CreateProjectResponseModel> responseCallback = await _fusionNetworkClient.post<CreateProjectResponseModel>(
        api: FusionApiEndpoint.projects,
        data: formData,
        fromJson: CreateProjectResponseModel.fromJson,
      );

      print("createProject responseCallback======${responseCallback.message}");

      if (responseCallback.success && responseCallback.data != null) {
        final CreateProjectEntity entity = responseCallback.data!.toEntity();

        return ResponseCallback<CreateProjectEntity>(
          success: true,
          message: responseCallback.message,
          data: entity,
        );
      } else {
        throw Exception('Project upload failed: ${responseCallback.message}');
      }
    } catch (e) {
      print(' Exception in ProjectSourceImpl: $e');
      return ResponseCallback<CreateProjectEntity>(
        success: false,
        message: 'Error creating project: $e',
      );
    }
  }

  /// Uploads a file to the server.
  @override
  Future<ResponseCallback<UploadFileEntity>> uploadFile({
    required String filename,
    required String filePath,
  }) async {
    try {
      final FormData formData = FormData.fromMap(<String, dynamic>{
        'file': await MultipartFile.fromFile(filePath, filename: '$filename.zip'),
      });

      final ResponseCallback<UploadFileResponseDto> responseCallback = await _fusionNetworkClient.post(
        api: FusionApiEndpoint.uploadFile,
        data: formData,
        fromJson: UploadFileResponseDto.fromJson,
      );

      if (responseCallback.success && responseCallback.data != null) {
        final UploadFileEntity entity = responseCallback.data!.toEntity();

        return ResponseCallback<UploadFileEntity>(
          success: true,
          message: responseCallback.message,
          data: entity,
        );
      } else {
        throw Exception('File upload failed: ${responseCallback.message}');
      }
    } catch (e) {
      print(' Exception in ProjectSourceImpl: $e');
      return ResponseCallback<UploadFileEntity>(
        success: false,
        message: 'Error uploading file: $e',
      );
    }
  }

  /// Fetches the project zip file from the server.
  @override
  Future<ResponseCallback<List<GetProjectsEntity>>> getProjectsData() async {
    try {
      final ResponseCallback<List<GetProjectsResponseDto>> response = await _fusionNetworkClient.getList(
        api: FusionApiEndpoint.projects,
        fromJson: (Map<String, dynamic> json) => GetProjectsResponseDto.fromJson(json),
      );

      if (response.success) {
        if (response.data == null || response.data!.isEmpty) {
          return ResponseCallback<List<GetProjectsEntity>>(
            success: true,
            message: 'No projects found.',
            data: <GetProjectsEntity>[],
          );
        }

        final List<GetProjectsEntity> entities = response.data!.map((GetProjectsResponseDto dto) => dto.toEntity()).toList();

        return ResponseCallback<List<GetProjectsEntity>>(
          success: true,
          message: response.message,
          data: entities,
        );
      } else {
        return ResponseCallback<List<GetProjectsEntity>>(
          success: false,
          message: response.message,
        );
      }
    } catch (e) {
      print('Exception in getProjectsData(): $e');
      return ResponseCallback<List<GetProjectsEntity>>(
        success: false,
        message: 'Exception occurred: $e',
      );
    }
  }

  /// Deletes a project by its ID.
  @override
  Future<ResponseCallback<void>> deleteProject({required String projectId}) async {
    try {
      final ResponseCallback<void> responseCallback = await _fusionNetworkClient.delete(
        api: FusionApiEndpoint.projects,
        additionalPath: projectId,
      );

      if (responseCallback.success) {
        return ResponseCallback<void>(
          success: true,
          message: responseCallback.message,
        );
      } else {
        throw Exception('Project deletion failed: ${responseCallback.message}');
      }
    } catch (e) {
      print('Exception in deleteProject(): $e');
      return ResponseCallback<void>(
        success: false,
        message: 'Error deleting project: $e',
      );
    }
  }

  /// Fetches a file by its ID.
  @override
  Future<ResponseCallback<Uint8List>> fetchFile({required String fileId}) async {
    try {
      final ResponseCallback<Uint8List> responseCallback = await _fusionNetworkClient.get(
        api: FusionApiEndpoint.fetchFile,
        additionalPath: fileId,
      );

      if (responseCallback.success && responseCallback.data != null) {
        return ResponseCallback<Uint8List>(
          success: true,
          message: 'Project zip downloaded and extracted successfully.',
          data: responseCallback.data,
        );
      } else {
        return ResponseCallback<Uint8List>(
          success: false,
          message: responseCallback.message,
        );
      }
    } catch (e) {
      return ResponseCallback<Uint8List>(
        success: false,
        message: 'Exception during download and extraction: $e',
      );
    }
  }

  /// up
  @override
  Future<ResponseCallback<void>> updateProject({
    required String name,
    required String id,
    required String description,
    required String metadata,
  }) async {
    try {
      final Map<String, dynamic> formData = <String, dynamic>{
        'name': name,
        'description': description,
        'metadata': metadata,
      };

      final ResponseCallback<void> responseCallback = await _fusionNetworkClient.put(
        api: FusionApiEndpoint.projects,
        data: formData,
        additionalPath: id,
      );

      if (responseCallback.success) {
        return ResponseCallback<void>(
          success: true,
          message: responseCallback.message,
        );
      } else {
        throw Exception('Project deletion failed: ${responseCallback.message}');
      }
    } catch (e) {
      print(' Exception in ProjectSourceImpl: $e');
      return ResponseCallback<CreateProjectEntity>(
        success: false,
        message: 'Error creating project: $e',
      );
    }
  }
}
