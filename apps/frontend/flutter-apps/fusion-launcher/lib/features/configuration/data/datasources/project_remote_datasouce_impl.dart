import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fusion_lib/fusion_networking/network/fusion_network_client.dart';
import 'package:fusion_lib/models/response_callback.dart';

import '../../../../core/models/project_metadata_model.dart';
import '../../../dashboard/data/models/upload_file_response_dto.dart';
import 'project_remote_datasouce.dart';

class ProjectRemoteDataSourceImpl implements ProjectRemoteDataSource {
  final FusionNetworkClient networkClient;

  ProjectRemoteDataSourceImpl({required this.networkClient});

  @override
  Future<String?> uploadFile(String filePath) async {
    try {
      final FormData formData = FormData.fromMap(<String, dynamic>{
        'file': await MultipartFile.fromFile(filePath),
      });

      final ResponseCallback<UploadFileResponseDto> response = await networkClient.post<UploadFileResponseDto>(
        api: FusionApiEndpoint.uploadFile,
        data: formData,
        fromJson: UploadFileResponseDto.fromJson,
      );

      if (response.success && response.data != null) {
        return response.data!.fileId;
      }
      return null;
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  @override
  Future<Uint8List?> downloadFile(String fileId) async {
    try {
      final ResponseCallback<Uint8List> response = await networkClient.get<Uint8List>(
        api: FusionApiEndpoint.fetchFile,
        additionalPath: fileId,
      );

      if (response.success && response.data != null) {
        return response.data;
      }
      return null;
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  @override
  Future<void> updateProject({
    required String id,
    required String name,
    required String description,
    required ProjectMetadataModel metadata,
  }) async {
    try {
      final Map<String, String> formData = <String, String>{
        'name': name,
        'description': description,
        'metadata': metadata.toString(),
      };

      final ResponseCallback<dynamic> response = await networkClient.put(
        api: FusionApiEndpoint.projects,
        data: formData,
        additionalPath: id,
      );

      if (!response.success) {
        throw Exception('Project update failed: ${response.message}');
      }
    } catch (e) {
      throw Exception('Update project failed: $e');
    }
  }
}
