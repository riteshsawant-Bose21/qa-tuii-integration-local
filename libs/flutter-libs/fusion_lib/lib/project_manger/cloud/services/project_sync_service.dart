import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../di/service_locator.dart';

/// Service to handle project folder compression and upload to AWS S3
class ProjectSyncService {
  final FusionNetworkClient networkClient;

  ProjectSyncService({required this.networkClient});

  /// Compress a project folder into a zip file
  /// Returns the path to the created zip file
  Future<File> compressProjectFolder({
    required String projectFolderPath,
    String? outputZipPath,
    void Function(double progress)? onProgress,
  }) async {
    final projectDir = Directory(projectFolderPath);

    if (!await projectDir.exists()) {
      throw Exception('Project folder does not exist: $projectFolderPath');
    }

    // Create output path if not provided
    if (outputZipPath == null) {
      final tempDir = await getTemporaryDirectory();
      final projectName = path.basename(projectFolderPath);
      outputZipPath = path.join(tempDir.path, '$projectName.zip');
    }

    final encoder = ZipFileEncoder();
    encoder.create(outputZipPath);

    // Get all files in the directory
    final files = await _getAllFiles(projectDir);
    final totalFiles = files.length;
    var processedFiles = 0;

    for (final file in files) {
      final relativePath = path.relative(file.path, from: projectFolderPath);
      encoder.addFile(file, relativePath);

      processedFiles++;
      onProgress?.call(processedFiles / totalFiles);
    }

    encoder.close();

    return File(outputZipPath);
  }

  /// Get all files recursively from a directory
  Future<List<File>> _getAllFiles(Directory dir) async {
    final files = <File>[];

    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        files.add(entity);
      }
    }

    return files;
  }

  /// Create a new project and get upload URLs
  Future<ResponseCallback<ProjectUploadUrls>> uploadProject({
    required ProjectData projectData,
  }) async {
    try {
      if (projectData.lastUploadedAt == null && !projectData.isCloudInstance) {
        Map<String, dynamic> data = {
          'projectId': projectData.id,
          'name': projectData.name,
          'application': projectData.application ?? 'General',
          'environment_type': projectData.environmentType ?? 'indoor',
          'description': projectData.description,
          'venue': projectData.venue ?? "gym",
          'budget': projectData.budget ?? {"amount": 50000, "currency": "USD"},
          'project_phase': projectData.projectPhase ?? 'Proposal',
          'is_project_file_created': true,
          'is_project_thumbnail_created': true,
        };
        ResponseCallback<ProjectUploadUrls> response = await networkClient.post(
          api: FusionApiEndpoint.projects,
          data: data,
          fromJson: (dynamic json) => ProjectUploadUrls.fromJson(json),
        );
        return response;
      } else {
        Map<String, dynamic> data = {
          'name': projectData.name,
          'application': projectData.application ?? 'General',
          'environment_type': projectData.environmentType ?? 'indoor',
          'description': projectData.description,
          'venue': projectData.venue ?? "gym",
          'budget': projectData.budget ?? {"amount": 50000, "currency": "USD"},
          'project_phase': projectData.projectPhase ?? 'Proposal',
          "is_project_file_dirty": true,
          "is_project_thumbnail_dirty": true,
        };
        return await _updateProjectAndGetUploadUrls(data: data, projectId: projectData.id);
      }
    } catch (e) {
      return ResponseCallback.failure(
        'Failed to create project: $e',
      );
    }
  }

  /// Update an existing project and get new upload URLs if needed
  Future<ResponseCallback<ProjectUploadUrls>> _updateProjectAndGetUploadUrls({
    required Map<String, dynamic> data,
    required String projectId,
  }) async {
    try {
      final response = await networkClient.patch(
        api: FusionApiEndpoint.projects,
        additionalPath: projectId,
        data: data,
        fromJson: (dynamic json) => ProjectUploadUrls.fromJson(json),
      );
      return response;
    } catch (e) {
      return ResponseCallback.failure(
        'Failed to update project: $e',
      );
    }
  }

  /// Upload zip file to AWS S3 using signed URL
  Future<void> uploadZipToS3({
    required String signedUrl,
    required File zipFile,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final fileLength = await zipFile.length();

      await Dio().put(
        signedUrl,
        data: zipFile.openRead(),
        options: Options(
          headers: {
            'Content-Type': 'application/zip',
            'Content-Length': fileLength,
          },
          // Don't send authorization header to S3
          followRedirects: false,
          validateStatus: (status) => status! < 400,
        ),
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw Exception('Failed to upload zip to S3: $e');
    }
  }

  Future<ResponseCallback<List<ProjectData>>> getAllProjectsFromCloud() async {
    try {
      final ResponseCallback<ProjectListResponse> response = await networkClient.get(
        api: FusionApiEndpoint.projects,
        fromJson: (dynamic json) => ProjectListResponse.fromJson(json),
      );

      if (response.success) {
        final SharedPreferencesHandler prefs = fusionLibLocator<SharedPreferencesHandler>();
        await prefs.setString(SharedPreferenceKeys.lastProjectSyncTime, DateTime.now().toUtc().toIso8601String());
      }

      if (!response.success) {
        return ResponseCallback.failure('Failed to fetch projects: ${response.message}');
      } else {
        return ResponseCallback.success(response.data?.projects ?? []);
      }
    } catch (e) {
      return ResponseCallback.failure(
        'Failed to fetch projects from cloud: $e',
      );
    }
  }

  Future<ResponseCallback<bool>> deleteProjectFromCloud({required String projectId}) async {
    try {
      ResponseCallback<dynamic> responseCallback = await networkClient.delete(
        api: FusionApiEndpoint.projects,
        additionalPath: projectId,
      );
      if (responseCallback.success) {
        return ResponseCallback.success(true);
      } else {
        return ResponseCallback.failure('Failed to delete project: ${responseCallback.message}');
      }
    } catch (e) {
      return ResponseCallback.failure(
        'Failed to delete project from cloud: $e',
      );
    }
  }

  Future<ResponseCallback<CloudSyncStatus>> downloadProjectZip({
    required String signedUrl,
    required String savePath,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await Dio().download(
        signedUrl,
        savePath,
        options: Options(
          followRedirects: false,
          validateStatus: (status) => status! < 400,
        ),
        onReceiveProgress: (received, total) {
          if (onProgress != null && total > 0) {
            onProgress(received / total);
          }
        },
        cancelToken: cancelToken,
      );
      return ResponseCallback.success(CloudSyncStatus.completed);
    } on DioException catch (dioError) {
      if (dioError.response != null && dioError.response?.statusCode == 403) {
        return ResponseCallback.failure(
          'Download URL has expired.',
          data: CloudSyncStatus.urlExpired,
        );
      } else {
        return ResponseCallback.failure(
          'Failed to download zip from S3: ${dioError.message}',
        );
      }
    } catch (e) {
      return ResponseCallback.failure(
        'Failed to download zip from S3: $e',
      );
    }
  }

  /// Unzips the project and creates a folder with the zip file's name
  /// [zipFilePath] - Path to the zip file
  /// [extractToPath] - Parent directory where the project folder will be created
  /// Returns the path to the extracted project directory
  Future<ResponseCallback<String>> unzipProject({
    required String zipFilePath,
    required String extractToPath,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final zipFile = File(zipFilePath);

      if (!await zipFile.exists()) {
        return ResponseCallback.failure('Zip file not found: $zipFilePath');
      }

      // Read the zip file
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      if (archive.isEmpty) {
        return ResponseCallback.failure('Zip file is empty');
      }

      // Use the zip file name (without .zip) as the folder name
      final folderName = path.basenameWithoutExtension(zipFilePath);

      // Create the extraction directory
      final extractDir = Directory(path.join(extractToPath, folderName));
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create(recursive: true);

      // Extract all files
      int totalFiles = archive.length;
      int extractedFiles = 0;

      for (final file in archive) {
        final fileName = file.name;

        // Build the full path directly (no root folder removal needed)
        final filePath = path.join(extractDir.path, fileName);

        if (file.isFile) {
          final outputFile = File(filePath);
          await outputFile.create(recursive: true);
          await outputFile.writeAsBytes(file.content as List<int>);
        } else {
          // It's a directory - create it
          await Directory(filePath).create(recursive: true);
        }

        extractedFiles++;
        if (onProgress != null) {
          onProgress(extractedFiles / totalFiles);
        }
      }

      return ResponseCallback.success(extractDir.path);
    } catch (e) {
      return ResponseCallback.failure('Failed to unzip project: $e');
    }
  }

  /// Complete download and unzip workflow
  Future<ResponseCallback<CloudSyncStatus>> downloadAndUnzipProject({
    required String signedUrl,
    required String projectId,
    required String downloadPath,
    required String extractToPath,
    void Function(String stage, double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      // Step 1: Download
      final zipPath = path.join(downloadPath, '$projectId.zip');

      ResponseCallback<CloudSyncStatus> downloadResult = await downloadProjectZip(
        signedUrl: signedUrl,
        savePath: zipPath,
        onProgress: (progress) {
          onProgress?.call('Downloading', progress);
        },
        cancelToken: cancelToken,
      );
      if (!downloadResult.success) {
        if (downloadResult.data == CloudSyncStatus.urlExpired) {
          final ResponseCallback<List<ProjectData>> allProjects = await getAllProjectsFromCloud();

          try {
            final ProjectData? updatedProject = allProjects.data?.firstWhere(
              (project) => project.id == projectId,
            );

            if (updatedProject != null) {
              // Retry download with new URL
              final retryDownloadResult = await downloadProjectZip(
                signedUrl: updatedProject.projectFileUrl!,
                savePath: zipPath,
                onProgress: (progress) {
                  onProgress?.call('Downloading', progress);
                },
                cancelToken: cancelToken,
              );

              if (!retryDownloadResult.success) {
                return ResponseCallback.failure(
                  'Download URL has expired and failed to refresh project data.',
                  data: CloudSyncStatus.urlExpired,
                );
              } else {
                // Update downloadResult to success for further processing
                downloadResult = retryDownloadResult;
              }
            } else {
              return ResponseCallback.failure(
                'Download URL has expired and failed to refresh project data.',
                data: CloudSyncStatus.urlExpired,
              );
            }
          } catch (e) {
            return ResponseCallback.failure(
              'Download URL has expired and failed to refresh project data.',
              data: CloudSyncStatus.urlExpired,
            );
          }
        } else {
          return ResponseCallback.failure(downloadResult.message, data: CloudSyncStatus.failed);
        }
      }

      // Step 2: Unzip
      final unzipResult = await unzipProject(
        zipFilePath: zipPath,
        extractToPath: extractToPath,
        onProgress: (progress) {
          onProgress?.call('Extracting', progress);
        },
      );

      if (!unzipResult.success) {
        return ResponseCallback.failure(unzipResult.message);
      }

      // Step 3: Cleanup - delete zip file
      final zipFile = File(zipPath);
      if (await zipFile.exists()) {
        await zipFile.delete();
      }

      return ResponseCallback.success(CloudSyncStatus.completed);
    } catch (e) {
      return ResponseCallback.failure(
        'Failed to download and unzip: $e',
        data: CloudSyncStatus.failed,
      );
    }
  }
}

enum CloudSyncStatus {
  notStarted,
  inProgress,
  completed,
  failed,
  urlExpired,
}

/// Model for project upload URLs response
class ProjectUploadUrls {
  final String? projectUploadUrl;
  final String? thumbnailUploadUrl;

  ProjectUploadUrls({
    this.projectUploadUrl,
    this.thumbnailUploadUrl,
  });

  factory ProjectUploadUrls.fromJson(Map<String, dynamic> json) {
    return ProjectUploadUrls(
      projectUploadUrl: json['project_upload_url'] as String?,
      thumbnailUploadUrl: json['thumbnail_upload_url'] as String?,
    );
  }
}
