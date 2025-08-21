import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/floor_entity.dart';
import 'package:fusion_launcher/core/models/project_list_model.dart';
import 'package:fusion_launcher/core/services/project_manager.dart';
import 'package:fusion_launcher/core/utils/helper.dart';
import 'package:fusion_launcher/features/dashboard/domain/entities/create_project_entity.dart';
import 'package:fusion_launcher/features/dashboard/domain/entities/get_projects_entity.dart';
import 'package:fusion_launcher/features/dashboard/domain/entities/upload_file_entity.dart';
import 'package:fusion_lib/fusion_networking/network/fusion_network_client.dart';
import 'package:fusion_lib/fusion_utils/shared_preference_handler.dart';
import 'package:fusion_lib/models/response_callback.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/dashboard/domain/usecases/create_project_usecase.dart';
import '../../features/dashboard/domain/usecases/delete_project_usecase.dart';
import '../../features/dashboard/domain/usecases/fetch_file_usecase.dart';
import '../../features/dashboard/domain/usecases/get_projects_data_usecase.dart';
import '../../features/dashboard/domain/usecases/update_project_usecase.dart';
import '../../features/dashboard/domain/usecases/upload_file_usecase.dart';
import '../models/floor_plan_entity.dart';
import '../models/project_entity.dart';
import '../models/project_metadata_model.dart';
import '../service_locator.dart';

class ProjectListManager extends ValueNotifier<List<ProjectListModel>> {
  ProjectListManager() : super(<ProjectListModel>[]);

  /// Add a new project
  void add(ProjectListModel project) {
    value = <ProjectListModel>[...value, project];
  }

  /// Remove a project by its id
  void remove(String id) {
    value = value.where((ProjectListModel p) => p.id != id).toList();
  }

  /// Find a project by id
  ProjectListModel? byId(String id) {
    try {
      return value.firstWhere((ProjectListModel p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Adds a new project to the list.
  /// If the project already exists, it will be replaced.
  Future<Directory> get fusionProjectDirectory async {
    final bool adminLogin = serviceLocator<SharedPreferencesHandler>().getBool(SharedPreferenceKeys.adminLogin) ?? false;
    final String fusionDirPath = adminLogin ? '/AdminFusionProject' : '/FusionProject';
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory fusionDir = Directory('${appDocDir.path}$fusionDirPath');

    if (!await fusionDir.exists()) {
      await fusionDir.create(recursive: true);
    }
    return fusionDir;
  }

  /// Returns a list of all project folders
  ///  in the Fusion project directory.
  Future<List<Directory>> getAllProjectFolders() async {
    final Directory fusionDir = await fusionProjectDirectory;
    final List<FileSystemEntity> entities = await fusionDir.list().toList();
    final List<Directory> folders = entities.whereType<Directory>().toList();

    return folders;
  }

  Future<void> loadProjects({
    void Function(String message)? onLoading,
    void Function(String error)? onError,
    void Function()? onComplete,
  }) async {
    final List<ProjectListModel> allProjects = <ProjectListModel>[];

    final SharedPreferencesHandler prefs = serviceLocator<SharedPreferencesHandler>();

    /// check for the token
    /// if not exists then do not load projects
    final bool isAdmin = prefs.getBool(SharedPreferenceKeys.adminLogin) ?? false;

    final String? accessToken = prefs.getString(SharedPreferenceKeys.accessToken);
    if ((accessToken == null || accessToken.isEmpty) && !isAdmin) {
      log('No access token found. Skipping project loading.');
      return;
    }

    try {
      final Directory fusionDir = await fusionProjectDirectory;

      /// Load local project_data.json files
      final List<Directory> projectFolders = await getAllProjectFolders();
      for (final Directory folder in projectFolders) {
        final File jsonFile = File('${folder.path}/project_data.json');
        if (!await jsonFile.exists()) continue;

        try {
          final String jsonStr = await jsonFile.readAsString();
          final Map<String, dynamic> projectData = jsonDecode(jsonStr);

          allProjects.add(ProjectListModel.fromJson(projectData));
        } catch (e) {
          onError?.call('Corrupt project in ${folder.path}: $e');
        }
      }

      /// Fetch from API only if NOT admin
      if (!isAdmin) {
        onLoading?.call("Fetching project metadata from server...");

        try {
          final GetProjectsDataUseCase getProjectsUseCase = serviceLocator<GetProjectsDataUseCase>();
          final ResponseCallback<List<GetProjectsEntity>> response = await getProjectsUseCase();

          if (response.success && response.data != null) {
            for (final GetProjectsEntity project in response.data!) {
              final String folderName = project.name.trim();
              final String nameKey = folderName.toLowerCase();

              final bool alreadyExists = allProjects.any(
                (ProjectListModel p) => p.name.trim().toLowerCase() == nameKey,
              );

              /// Skip if project already exists
              if (!alreadyExists) {
                final Directory projectDir = Directory('${fusionDir.path}/$folderName');
                await projectDir.create(recursive: true);

                allProjects.add(
                  ProjectListModel(
                    id: project.id.toString(), // dbId
                    name: folderName,
                    metaData: ProjectMetadataModel.fromJson(
                      jsonDecode(project.metadata),
                    ),
                    colors: Helper.randomColors(),
                    createdAt: project.createdAt,
                    updatedAt: project.updatedAt,
                  ),
                );
              }
            }
          } else {
            onError?.call('API error: ${response.message}');
          }
        } catch (e) {
          onError?.call('Unexpected error while fetching projects: $e');
        }
      }

      // Finalize
      allProjects.sort((ProjectListModel a, ProjectListModel b) => b.updatedAt.compareTo(a.updatedAt));
      super.value = allProjects;

      log(" Loaded ${allProjects.length} project(s).");
      onComplete?.call();
      //
    } catch (e) {
      onError?.call('Unexpected error in loadProjects(): $e');
    }
  }

  /// Creates a new project folder
  /// with the given name.
  /// inside the Fusion project directory.
  Future<String?> createNewProject({
    required String name,
    required ProjectManager projectManager,
  }) async {
    final bool adminLogin = serviceLocator<SharedPreferencesHandler>().getBool(SharedPreferenceKeys.adminLogin) ?? false;

    final String folderName = name.trim().isEmpty ? 'New Project' : name.trim();
    final int newId = Helper.generateUniqueId();
    final DateTime now = DateTime.now();
    final List<Color> newColor = Helper.randomColors();

    try {
      final Directory fusionDir = await fusionProjectDirectory;
      final Directory projectDir = Directory('${fusionDir.path}/$folderName');

      /// Check if folder already exists
      if (await projectDir.exists()) {
        return 'Project folder "$folderName" already exists.';
      }

      /// Create the new folder
      await projectDir.create(recursive: true);

      final String sampleMetadata =
          ProjectMetadataModel(
            fileId: '',
            thumbnailUrl: '',
            projectName: folderName,
          ).toString();

      /// Create the project entity
      final ProjectEntity newProject = ProjectEntity(
        id: newId.toString(),
        name: folderName,
        colors: newColor,
        floors: <Floor>[
          Floor(
            name: "Floor 1",
            floorPlan: FloorPlanEntity.defaultFloorPlan,
          ),
        ],
        createdAt: now,
        updatedAt: now,
        metaData: sampleMetadata,
      );

      /// Write the project data to a JSON file
      final File jsonFile = File('${projectDir.path}/project_data.json');
      await jsonFile.writeAsString(jsonEncode(newProject.toJson()));

      String finalProjectId = newId.toString();
      String fileMetaData = "";

      /// If not an admin login, zip the project folder
      /// and upload it to the server
      if (!adminLogin) {
        /// Zip the folder
        /// and prepare it for upload
        final File zipFile = await Helper.zipFusionProjectFolder(projectDir);

        /// usecase instances
        final UploadFileUseCase uploadFileUseCase = serviceLocator<UploadFileUseCase>();
        final CreateProjectUseCase createProjectUsecase = serviceLocator<CreateProjectUseCase>();

        /// Upload the zip file to the server
        final ResponseCallback<UploadFileEntity> uploadResponse = await uploadFileUseCase(
          filename: newId.toString(), // just to save fileId &newId.zip
          filePath: zipFile.path,
        );

        /// Check if the upload was successful
        if (!uploadResponse.success) {
          await _cleanup(projectDir, zipFile);
          return 'Failed to upload project file: ${uploadResponse.message}';
        }

        fileMetaData =
            ProjectMetadataModel(
              fileId: uploadResponse.data!.fileId,
              thumbnailUrl: '',
              projectName: folderName,
            ).toString();

        /// Create the project on the server
        final ResponseCallback<CreateProjectEntity> createResponse = await createProjectUsecase(
          name: folderName,
          description: '$folderName Created on ${now.toIso8601String()}',
          // metadata: uploadResponse.data!.fileId,
          metadata: fileMetaData,
        );

        /// Check if the project creation was successful
        if (!createResponse.success) {
          await _cleanup(projectDir, zipFile);
          return 'Failed to create project: ${createResponse.message}';
        }

        /// Update the final project ID
        finalProjectId = createResponse.data!.id.toString();

        /// Create a copy with the correct cloudId
        final ProjectEntity updatedProject = newProject.copyWith(cloudId: finalProjectId, metaData: fileMetaData);
        await jsonFile.writeAsString(jsonEncode(updatedProject.toJson()));

        final File zipFileUpdated = await Helper.zipFusionProjectFolder(projectDir);
        if (zipFileUpdated == null) {
          await _cleanup(projectDir, zipFileUpdated);
          return 'Failed to create zip file for project.';
        }

        final ResponseCallback<UploadFileEntity> uploadResponseUpdated = await uploadFileUseCase(
          filename: newId.toString(), // just to save fileId &newId.zip
          filePath: zipFileUpdated.path,
        );
        if (!uploadResponseUpdated.success) {
          await _cleanup(projectDir, zipFileUpdated);
          return 'Failed to upload project file: ${uploadResponseUpdated.message}';
        } else {
          final UpdateProjectUsecase updateProjectUsecase = serviceLocator<UpdateProjectUsecase>();

          fileMetaData =
              ProjectMetadataModel(
                fileId: uploadResponseUpdated.data!.fileId,
                thumbnailUrl: '',
                projectName: folderName,
              ).toString();

          final ResponseCallback<void> updateResponse = await updateProjectUsecase(
            name: folderName,
            id: finalProjectId,
            description: "updated $folderName on ${now.toIso8601String()}",
            metadata: fileMetaData,
          );
          print('Project sync response: ${updateResponse.success} - ${updateResponse.message}');
        }

        if (await zipFile.exists()) await zipFile.delete();
        if (await zipFileUpdated.exists()) await zipFileUpdated.delete();
      } else {
        /// Admin login: no upload, just create the folder
        fileMetaData =
            ProjectMetadataModel(
              fileId: '',
              thumbnailUrl: '',
              projectName: folderName,
            ).toString();
      }

      projectManager.loadProject(folderName);

      /// Add the new project to the list
      final ProjectListModel newProjectListModel = ProjectListModel(
        id: finalProjectId,
        // id: newId.toString(),
        name: folderName,
        metaData: ProjectMetadataModel.fromJson(
          jsonDecode(fileMetaData),
        ),
        colors: newColor,
        createdAt: now,
        updatedAt: now,
      );

      /// Update the project manager
      value = <ProjectListModel>[newProjectListModel, ...value];

      return null; // Success - no error message
    } catch (e, stack) {
      log('Exception during project creation: $e\n$stack');
      return 'Unexpected error: $e';
    }
  }

  Future<void> _cleanup(Directory dir, File zipFile) async {
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    if (await zipFile.exists()) {
      await zipFile.delete();
    }
  }

  /// Deletes a project folder
  Future<void> deleteProject({
    required String folderName,
    required String projectId,
  }) async {
    final SharedPreferencesHandler prefs = serviceLocator<SharedPreferencesHandler>();
    final bool isAdmin = prefs.getBool(SharedPreferenceKeys.adminLogin) ?? false;

    /// Admin: directly delete the local folder only
    if (isAdmin) {
      await _deleteLocalFolder(folderName);
      return;
    }

    /// Non-admin: call delete API first
    final DeleteProjectUseCase deleteUseCase = serviceLocator<DeleteProjectUseCase>();
    final ResponseCallback<void> response = await deleteUseCase(projectId: projectId);

    if (response.success) {
      /// Only delete local folder if API was successful
      await _deleteLocalFolder(folderName);
    } else {
      throw Exception('Failed to delete project from server: ${response.message}');
    }
  }

  Future<void> _deleteLocalFolder(String folderName) async {
    final Directory fusionDir = await fusionProjectDirectory;
    final Directory projectDir = Directory('${fusionDir.path}/$folderName');

    if (await projectDir.exists()) {
      try {
        await projectDir.delete(recursive: true);
        log('Project folder "$folderName" deleted successfully.');
      } catch (e) {
        log('Error deleting project folder "$folderName": $e');
        throw Exception('Could not delete project folder "$folderName".');
      }
    } else {
      log('Error: Project folder "$folderName" does not exist.');
      throw Exception('Project folder "$folderName" not found.');
    }
  }

  /// Deletes the Fusion project directory
  Future<void> deleteFusionProjectDirectory() async {
    final bool isAdmin = serviceLocator<SharedPreferencesHandler>().getBool(SharedPreferenceKeys.adminLogin) ?? false;
    if (isAdmin) {
      log('Admin mode: Skipping deletion of Fusion project directory.');
      return;
    }
    final Directory fusionDir = await fusionProjectDirectory;

    if (await fusionDir.exists()) {
      try {
        await fusionDir.delete(recursive: true);
        log('Fusion project directory deleted successfully.');
      } catch (e) {
        log('Error deleting Fusion project directory: $e');
        throw Exception('Could not delete Fusion project directory.');
      }
    } else {
      log('Fusion project directory does not exist.');
    }
  }

  Future<void> downloadAndExtractProjectZip({
    required String fileId,
    required String projectName,
    required ProjectManager projectManager,
    required DateTime localUpdatedAt,
    void Function(String msg)? onError,
    void Function()? onSuccess,
  }) async {
    final SharedPreferencesHandler prefs = serviceLocator<SharedPreferencesHandler>();
    final bool isAdmin = prefs.getBool(SharedPreferenceKeys.adminLogin) ?? false;

    if (isAdmin) {
      /// Admins should not download from server
      await projectManager.loadProject(projectName);
      onSuccess?.call();
      log("Admin mode: Loaded local project '$projectName'.");
      return;
    }

    try {
      final Directory fusionDir = await fusionProjectDirectory;
      final Directory projectDir = Directory('${fusionDir.path}/$projectName');
      final File localProjectDataFile = File('${projectDir.path}/project_data.json');

      if (await localProjectDataFile.exists()) {
        projectManager.loadProject(projectName);
        onSuccess?.call();
        log("Project '$projectName' loaded Successfully from local.");
      } else {
        final FetchFileUsecase fileUseCase = serviceLocator<FetchFileUsecase>();
        final ResponseCallback<Uint8List> response = await fileUseCase(fileId: fileId);

        if (!response.success || response.data == null) {
          onError?.call("Failed to download project file: ${response.message}");
          return;
        }
        await Helper.unzipFile(response.data!, projectDir);
        projectManager.loadProject(projectName);
      }
    } catch (e) {
      onError?.call("Extraction error: $e");
    }
  }

  /// sync projects from cloud
  Future<(bool success, String message)> syncProjectsFromCloud() async {
    final SharedPreferencesHandler prefs = serviceLocator<SharedPreferencesHandler>();
    final bool isAdmin = prefs.getBool(SharedPreferenceKeys.adminLogin) ?? false;
    if (isAdmin) {
      log('Admin mode: Skipping cloud sync.');
      return (true, 'Admin mode: Skipping cloud sync.');
    }

    try {
      final GetProjectsDataUseCase getProjectsUseCase = serviceLocator<GetProjectsDataUseCase>();
      final ResponseCallback<List<GetProjectsEntity>> response = await getProjectsUseCase();
      if (response.success) {
        print("sync succes");
        value.clear();

        /// remove all existing projects from Fusion project directory
        final Directory fusionDir = await fusionProjectDirectory;
        if (await fusionDir.exists()) {
          await fusionDir.delete(recursive: true);
          await fusionDir.create(recursive: true);
        }
        log('Syncing projects from cloud... ${response.data?.length} project(s) found.');

        for (final GetProjectsEntity project in response.data!) {
          final String folderName = project.name.trim();
          final Directory projectDir = Directory('${fusionDir.path}/$folderName');

          if (!await projectDir.exists()) {
            await projectDir.create(recursive: true);
          }

          value.add(
            ProjectListModel(
              id: project.id.toString(),
              name: folderName,
              metaData: ProjectMetadataModel.fromJson(
                jsonDecode(project.metadata),
              ),
              colors: Helper.randomColors(),
              createdAt: project.createdAt,
              updatedAt: project.updatedAt,
            ),
          );
        }

        value.sort((ProjectListModel a, ProjectListModel b) => b.updatedAt.compareTo(a.updatedAt));
        notifyListeners();
        log('Successfully synced projects from cloud.');
        return (true, 'Successfully synced projects from cloud.');
      } else {
        return (true, 'Successfully synced projects from cloud.');
      }
    } catch (e) {
      log('Error syncing projects from cloud: $e');
      return (false, 'Unexpected error: $e');
    }
  }

  Future<File?> downloadThumbnailFile({required String fileId}) async {
    try {
      final Directory fusionDir = await fusionProjectDirectory;
      final File thumbnailFile = File('${fusionDir.path}/$fileId');

      if (await thumbnailFile.exists()) return thumbnailFile;

      final ResponseCallback<Uint8List> responseCallback = await serviceLocator<FusionNetworkClient>().get(
        api: FusionApiEndpoint.fetchFile,
        additionalPath: fileId,
      );

      if (responseCallback.success && responseCallback.data != null) {
        await thumbnailFile.writeAsBytes(responseCallback.data!);
        log('File fetched successfully: ${thumbnailFile.path}');
        return thumbnailFile;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  void updateProjectMetadataName({
    required String fileId,
    required String newName,
  }) async {
    final int index = value.indexWhere((ProjectListModel p) => p.id == fileId);
    if (index != -1) {
      final ProjectListModel updatedProject = value[index].copyWith(
        metaData: value[index].metaData.copyWith(
          projectName: newName,
        ),
      );
      value[index] = updatedProject;
      notifyListeners();
      print('Project name updated to $newName for ID $fileId');
    } else {
      log('Project with ID $fileId not found for name update.');
    }
  }
}
