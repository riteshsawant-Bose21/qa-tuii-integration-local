import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../authentication/viewmodel/session_view_model.dart';

part 'project_sync_view_model_state.dart';

/// Cubit for managing project upload state
class ProjectSyncViewModel extends Cubit<ProjectSyncViewModelState> {
  final ProjectSyncService _uploadService;
  CancelToken? _cancelToken;

  ProjectSyncViewModel(this._uploadService) : super(ProjectUploadInitial());

  Future<void> getAllProjectsToUpload() async {
    emit(LoadingAllProjects());
    final ResponseCallback<List<ProjectData>> response = await _uploadService.getAllProjectsFromCloud();
    if (response.success && response.data != null) {
      emit(AllProjectsLoaded(projects: response.data!));
    } else {
      emit(ProjectsLoadFailure(error: response.message));
    }
  }

  /// Upload a new project
  Future<void> uploadProject({
    required ProjectData projectData,
  }) async {
    try {
      _cancelToken = CancelToken();
      emit(
        ProjectUploadInProgress(progress: 0.0, projectId: projectData.id),
      );

      if (projectData.isCloudInstance) {
        emit(ProjectUploadSuccess(projectId: projectData.id));
        return;
      }

      final ResponseCallback<ProjectUploadUrls> uploadResponse = await _uploadService.uploadProject(projectData: projectData);

      if (!uploadResponse.success || uploadResponse.data == null) {
        emit(ProjectUploadFailure(error: uploadResponse.message));
        return;
      }

      //update last sync time
      await serviceLocator<ProjectViewModel>().updateProjectLastSyncedAt(projectId: projectData.id, lastSyncedAt: DateTime.now().toUtc());
      await serviceLocator<ProjectViewModel>().loadAllLocalProjects();

      if (uploadResponse.data!.projectUploadUrl != null) {
        final File projectZipFile = await serviceLocator<ProjectViewModel>().getProjectZipFile(projectId: projectData.id);
        //now upload project zip
        await _uploadService.uploadZipToS3(
          zipFile: projectZipFile,
          signedUrl: uploadResponse.data!.projectUploadUrl!,
          onProgress: (double progress) {
            emit(
              ProjectUploadInProgress(
                progress: progress,
                projectId: projectData.id,
              ),
            );
          },
          cancelToken: _cancelToken,
        );
      }

      // // Similarly, upload thumbnail if URL is provided
      // if (uploadResponse.data!.thumbnailUploadUrl != null) {
      //   final File thumbnailFile = await serviceLocator<ProjectViewModel>().getProjectThumbnailFile(projectId: projectData.id);
      //   await _uploadService.uploadZipToS3(
      //     zipFile: thumbnailFile,
      //     signedUrl: uploadResponse.data!.thumbnailUploadUrl!,
      //     onProgress: (double progress) {
      //       // Optionally handle thumbnail upload progress
      //     },
      //     cancelToken: _cancelToken,
      //   );
      // }

      emit(ProjectUploadSuccess(projectId: projectData.id));
    } catch (e) {
      emit(ProjectUploadFailure(error: e.toString()));
    } finally {
      _cancelToken = null;
    }
  }

  Future<void> uploadAllProjects() async {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    final List<ProjectData> projects = await projectViewModel.getAllProjectsToUpload();

    for (final ProjectData project in projects) {
      await uploadProject(projectData: project);
      final ProjectSyncViewModelState currentState = state;
      if (currentState is ProjectUploadFailure) {
        // Stop uploading further projects if one fails
        break;
      }
    }
  }

  Future<ResponseCallback<CloudSyncStatus>> downloadProject(ProjectData projectData) async {
    if (projectData.projectFileUrl == null) {
      emit(const ProjectDownloadFailure(error: "Project file URL is null"));
      return ResponseCallback<CloudSyncStatus>.failure("Project file URL is null");
    }

    emit(ProjectDownloadInProgress(progress: 0.0, projectId: projectData.id));

    final Directory fusionProjectDir = await serviceLocator<ProjectViewModel>().getFusionProjectsDirectory();
    final ResponseCallback<CloudSyncStatus> downloadResponse = await _uploadService.downloadAndUnzipProject(
      signedUrl: projectData.projectFileUrl!,
      projectId: projectData.id,
      downloadPath: fusionProjectDir.path,
      extractToPath: fusionProjectDir.path,
      onProgress: (String phase, double progress) {
        emit(ProjectDownloadInProgress(progress: progress, projectId: projectData.id, downloadPhase: phase));
      },
    );

    if (downloadResponse.success && downloadResponse.data != null && downloadResponse.data == CloudSyncStatus.completed) {
      emit(ProjectDownloadSuccess(projectId: projectData.id));
    } else {
      emit(ProjectDownloadFailure(error: downloadResponse.message));
    }
    return downloadResponse;
  }

  /// Cancel ongoing upload
  void cancelUpload() {
    _cancelToken?.cancel('Upload cancelled by user');
    emit(ProjectUploadCancelled());
  }

  /// Reset to initial state
  void reset() {
    emit(ProjectUploadInitial());
  }

  Future<void> getAllProjects({bool forceFetch = false}) async {
    emit(LoadingAllProjects());
    final SharedPreferencesHandler prefs = serviceLocator<SharedPreferencesHandler>();
    final String? lastCloudSyncTime = prefs.getString(SharedPreferenceKeys.lastProjectSyncTime);
    if (lastCloudSyncTime != null && !forceFetch) {
      //since we already synced projects before, we just load them locally
      await serviceLocator<ProjectViewModel>().loadAllLocalProjects();
      emit(AllProjectsLoaded(projects: serviceLocator<ProjectViewModel>().allProjects));
    } else {
      //first time sync, so we fetch from cloud
      final ResponseCallback<List<ProjectData>> response = await _uploadService.getAllProjectsFromCloud();

      if (response.success && response.data != null) {
        //save projects locally
        await serviceLocator<ProjectViewModel>().saveProjects(response.data!);
        await serviceLocator<ProjectViewModel>().loadAllLocalProjects();
        emit(AllProjectsLoaded(projects: response.data!));
      } else {
        emit(ProjectsLoadFailure(error: response.message));
      }
    }
  }

  Future<void> deleteProject({required String projectId}) async {
    final bool hasCloudAccess = serviceLocator<SessionViewModel>().hasCloudAccess();
    if (!hasCloudAccess) {
      await serviceLocator<ProjectViewModel>().deleteProjectFromLocal(projectId);
      //if user is in offline mode, we don't delete from cloud
      return;
    }

    await serviceLocator<ProjectViewModel>().softDeleteProject(projectId);

    final ResponseCallback<bool> response = await _uploadService.deleteProjectFromCloud(projectId: projectId);
    print("Delete project response: ${response.success}, message: ${response.message}");
    if (response.success && response.data == true) {
      await serviceLocator<ProjectViewModel>().deleteProjectFromLocal(projectId);
    } else {
      emit(ProjectsLoadFailure(error: response.message));
    }
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel();
    return super.close();
  }
}
