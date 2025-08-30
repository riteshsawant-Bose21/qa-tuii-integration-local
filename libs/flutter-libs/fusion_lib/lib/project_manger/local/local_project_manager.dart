import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_logger/logger.dart';
import 'package:path_provider/path_provider.dart';

const String kFusionProjectDirName = '/FusionProject';
const String kAdminFusionProjectDirName = '/AdminFusionProject';
const String kProjectDataFileName = 'project_data.json';

class LocalProjectManager {
  final SharedPreferencesHandler sharedPreferencesHandler;

  LocalProjectManager({required this.sharedPreferencesHandler});

  /// Adds a new project to the list.
  /// If the project already exists, it will be replaced.
  Future<Directory> get fusionProjectDirectory async {
    final bool adminLogin = sharedPreferencesHandler.getBool(SharedPreferenceKeys.adminLogin) ?? false;
    final String fusionDirPath = adminLogin ? kFusionProjectDirName : kFusionProjectDirName;
    final Directory appDocDir = await getApplicationCacheDirectory();
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

  Future<ResponseCallback<List<ProjectData>>> loadProjects() async {
    final List<ProjectData> allProjects = <ProjectData>[];

    /// check for the token
    /// if not exists then do not load projects
    final bool isAdmin = sharedPreferencesHandler.getBool(SharedPreferenceKeys.adminLogin) ?? false;

    final String? accessToken = sharedPreferencesHandler.getString(SharedPreferenceKeys.accessToken);

    if ((accessToken == null || accessToken.isEmpty) && !isAdmin) {
      FusionLogger.log(tag: LogTag.project, message: "No access token found. Skipping project load.");
      return ResponseCallback.failure('No access token found. Please log in.');
    }

    try {
      /// Load local project_data.json files
      final List<Directory> projectFolders = await getAllProjectFolders();
      for (final Directory folder in projectFolders) {
        final File jsonFile = File('${folder.path}/$kProjectDataFileName');
        if (!await jsonFile.exists()) continue;

        final String jsonStr = await jsonFile.readAsString();
        final Map<String, dynamic> projectData = jsonDecode(jsonStr);

        allProjects.add(ProjectData.fromJson(projectData));
      }

      return ResponseCallback.success(allProjects);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Error loading projects: $e", logLevel: LogLevel.error);
      return ResponseCallback.failure('Error loading projects: $e');
    }
  }

  /// Creates a new project folder
  /// with the given name.
  /// inside the Fusion project directory.
  Future<ResponseCallback<ProjectData?>> createNewProject({required NewProjectDetails projectDetails}) async {
    final bool adminLogin = sharedPreferencesHandler.getBool(SharedPreferenceKeys.adminLogin) ?? false;

    final String projectId = FusionUtils.shortStringUUID();
    final DateTime now = DateTime.now();
    final List<Color> newColor = FusionUtils.randomColors();

    try {
      final Directory fusionDir = await fusionProjectDirectory;
      final Directory projectDir = Directory('${fusionDir.path}/$projectId');

      /// Check if folder already exists
      if (await projectDir.exists()) {
        return ResponseCallback.failure("Project folder '$projectId' already exists.");
      }

      /// Create the new folder
      await projectDir.create(recursive: true);

      final String sampleMetadata = ProjectMetadataModel(fileId: '', thumbnailUrl: '', projectName: projectDetails.name).toString();

      /// Create the project entity
      final ProjectData newProject = ProjectData(
        id: projectId,
        name: projectDetails.name,
        metaData: sampleMetadata,
        projectRawData: {
          'id': projectId,
          'name': projectDetails.name,
          'metaData': sampleMetadata,
          'colors': newColor.map((Color color) => color.value).toList(),
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        },
      );

      /// Write the project data to a JSON file
      final File jsonFile = File('${projectDir.path}/$kProjectDataFileName');
      await jsonFile.writeAsString(jsonEncode(newProject.toJson()));

      return ResponseCallback.success(newProject); // Success - no error message
    } catch (e, stack) {
      FusionLogger.log(tag: LogTag.project, message: 'Exception during project creation: $e\n$stack');
      return ResponseCallback.failure('Error creating project: $e');
    }
  }

  ///save all projects to fusion project directory
  Future<ResponseCallback<bool>> saveProjects(List<ProjectData> projects) async {
    try {
      final Directory fusionDir = await fusionProjectDirectory;

      for (final ProjectData project in projects) {
        final Directory projectDir = Directory('${fusionDir.path}/${project.id}');

        if (!await projectDir.exists()) {
          await projectDir.create(recursive: true);
        }

        final File jsonFile = File('${projectDir.path}/$kProjectDataFileName');
        await jsonFile.writeAsString(jsonEncode(project.projectRawData));
      }

      return ResponseCallback.success(true);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'Error saving projects: $e', logLevel: LogLevel.error);
      return ResponseCallback.failure('Error saving projects: $e');
    }
  }

  ///save single project to fusion project directory
  Future<ResponseCallback<bool>> saveProject(ProjectData project) async {
    try {
      final Directory fusionDir = await fusionProjectDirectory;

      final Directory projectDir = Directory('${fusionDir.path}/${project.id}');

      if (!await projectDir.exists()) {
        await projectDir.create(recursive: true);
      }

      final File jsonFile = File('${projectDir.path}/$kProjectDataFileName');
      await jsonFile.writeAsString(jsonEncode(project.projectRawData));

      return ResponseCallback.success(true);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'Error saving projects: $e', logLevel: LogLevel.error);
      return ResponseCallback.failure('Error saving projects: $e');
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
  Future<ResponseCallback<bool>> deleteProject({required String projectId}) async {
    return await deleteLocalFolder(projectId);
  }

  Future<ResponseCallback<bool>> deleteLocalFolder(String projectId) async {
    final Directory fusionDir = await fusionProjectDirectory;
    final Directory projectDir = Directory('${fusionDir.path}/$projectId');

    if (await projectDir.exists()) {
      try {
        await projectDir.delete(recursive: true);
        FusionLogger.log(tag: LogTag.project, message: 'Project folder "$projectId" deleted successfully.');
        return ResponseCallback.success(true);
      } catch (e) {
        FusionLogger.log(tag: LogTag.project, message: 'Error deleting project folder "$projectId": $e');
        return ResponseCallback.failure('Could not delete project folder "$projectId": $e');
      }
    } else {
      FusionLogger.log(tag: LogTag.project, message: 'Error: Project folder "$projectId" does not exist.');
      return ResponseCallback.failure('Project folder "$projectId" does not exist.');
    }
  }

  /// Deletes the Fusion project directory
  Future<ResponseCallback<bool>> deleteFusionProjectDirectory() async {
    final bool isAdmin = sharedPreferencesHandler.getBool(SharedPreferenceKeys.adminLogin) ?? false;
    if (isAdmin) {
      FusionLogger.log(tag: LogTag.project, message: 'Admin mode: Skipping deletion of Fusion project directory.');
      return ResponseCallback.success(true);
    }
    final Directory fusionDir = await fusionProjectDirectory;

    if (await fusionDir.exists()) {
      try {
        await fusionDir.delete(recursive: true);
        FusionLogger.log(tag: LogTag.project, message: 'Fusion project directory deleted successfully.');
        return ResponseCallback.success(true);
      } catch (e) {
        FusionLogger.log(tag: LogTag.project, message: 'Error deleting Fusion project directory: $e');
        return ResponseCallback.failure('Could not delete Fusion project directory: $e');
      }
    } else {
      FusionLogger.log(tag: LogTag.project, message: 'Fusion project directory does not exist.');
      return ResponseCallback.success(true);
    }
  }
}
