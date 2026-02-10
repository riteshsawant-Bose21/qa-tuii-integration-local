import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

const String kFusionProjectDirName = '/FusionProject';
const String kFusionMediaDirectory = '/MediaFiles';
const String kAdminFusionProjectDirName = '/AdminFusionProject';
const String kProjectDataFileName = 'project_data.json';

class LocalProjectManager {
  final SharedPreferencesHandler sharedPreferencesHandler;

  LocalProjectManager({required this.sharedPreferencesHandler});

  /// Adds a new project to the list.
  /// If the project already exists, it will be replaced.
  Future<Directory> get fusionProjectDirectory async {
    final String fusionDirPath = kFusionProjectDirName;
    Directory appDocDir = await FusionUtils.getFusionAppDirectory();
    final Directory fusionDir = Directory('${appDocDir.path}$fusionDirPath');

    // print("Fusion Project Directory: ${fusionDir.path}");

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

    // final String? accessToken = sharedPreferencesHandler.getString(SharedPreferenceKeys.accessToken);
    //
    // if ((accessToken == null || accessToken.isEmpty) && !isAdminLogin) {
    //   FusionLogger.log(tag: LogTag.project, message: "No access token found. Skipping project load.");
    //   return ResponseCallback.failure('No access token found. Please log in.');
    // }

    try {
      /// Load local project_data.json files
      final List<Directory> projectFolders = await getAllProjectFolders();
      for (final Directory folder in projectFolders) {
        final File jsonFile = File('${folder.path}/$kProjectDataFileName');
        if (!await jsonFile.exists()) continue;

        try {
          final String jsonStr = await jsonFile.readAsString();
          final Map<String, dynamic> projectData = jsonDecode(jsonStr);
          ProjectData project = ProjectData.fromJson(projectData);
          if (!project.isDeleted) {
            allProjects.add(project);
          }
        } catch (e) {
          FusionLogger.log(tag: LogTag.project, message: "Error reading project data from folder ${folder.path}: $e", logLevel: LogLevel.error);
        }
      }

      return ResponseCallback.success(allProjects);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Error loading projects: $e", logLevel: LogLevel.error);
      return ResponseCallback.failure('Error loading projects: $e');
    }
  }

  Future<Directory> getProjectDirectoryById(String projectId) async {
    final Directory fusionDir = await fusionProjectDirectory;
    final Directory projectDir = Directory('${fusionDir.path}/$projectId');
    return projectDir;
  }

  Future<Directory> getProjectMediaDirectory({required String projectId}) async {
    final String mediaDirPath = kFusionMediaDirectory;
    Directory appDocDir = await getProjectDirectoryById(projectId);
    final Directory mediaDir = Directory('${appDocDir.path}$mediaDirPath');

    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir;
  }

  Future<File> zipProjectDirectory(String projectId) async {
    final Directory projectDir = await getProjectDirectoryById(projectId);

    if (!await projectDir.exists()) {
      throw Exception("Project directory not found: ${projectDir.path}");
    }

    final String zipPath = '${projectDir.path}.zip';
    final File zipFile = File(zipPath);

    // Delete existing zip file
    if (await zipFile.exists()) {
      await zipFile.delete();
    }

    try {
      // Create archive in memory
      final archive = Archive();

      // Get all entities recursively
      final entities = projectDir.listSync(recursive: true);

      for (final entity in entities) {
        final relativePath = entity.path.substring(projectDir.path.length + 1);

        if (entity is File) {
          // Add file with its content
          final bytes = await entity.readAsBytes();
          final archiveFile = ArchiveFile(relativePath, bytes.length, bytes);
          archive.addFile(archiveFile);
        } else if (entity is Directory) {
          // Add directory entry (with trailing slash)
          final archiveFile = ArchiveFile('$relativePath/', 0, []);
          archive.addFile(archiveFile);
        }
      }

      // Encode to zip
      final zipData = ZipEncoder().encode(archive);

      if (zipData == null) {
        throw Exception("Failed to encode zip file");
      }

      // Write to file
      await zipFile.writeAsBytes(zipData);

      return zipFile;
    } catch (e) {
      // Cleanup partial zip on error
      if (await zipFile.exists()) {
        await zipFile.delete();
      }
      rethrow;
    }
  }

  /// Creates a new project folder
  /// with the given name.
  /// inside the Fusion project directory.
  Future<ResponseCallback<ProjectData?>> createNewProject({required NewProjectDetails projectDetails}) async {
    final String projectId = FusionUtils.generateUUID();
    final DateTime now = DateTime.now().toUtc();
    final List<Color> newColor = FusionUtils.randomColors();

    try {
      final Directory fusionDir = await fusionProjectDirectory;
      final Directory projectDir = Directory('${fusionDir.path}/$projectId');

      print('Creating new project directory at: ${projectDir.path}');

      /// Check if folder already exists
      if (await projectDir.exists()) {
        return ResponseCallback.failure("Project folder '$projectId' already exists.");
      }

      /// Create the new folder
      await projectDir.create(recursive: true);

      Map<String, dynamic> newProjectData = {
        'id': projectId,
        'name': projectDetails.name,
        'projectName': projectDetails.name,
        'colors': newColor.map((Color color) => '0x${color.toARGB32().toRadixString(16).padLeft(8, '0')}').toList(),
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        "virtualIP": null,
        "currentFloorIndex": 0,
        "droResponse": null,
        "minSPL": 36.0,
        "maxSPL": 132.0,
        "isInControlMode": false,
        "isInHardwareMode": false,
        "application": null,
        "budget": null,
        "description": null,
        "environment_type": null,
        "is_archived": false,
        "is_starred": false,
        "locked_by_user": null,
        "project_file_url": null,
        "project_phase": null,
        "thumbnail_url": null,
        "venue": null,
        "lastUploadedAt": null,
        "isCloudInstance": false,
        "is_deleted": false,
        "floors": [
          {
            "id": "FLOOR${FusionUtils.shortStringUUID()}",
            'name': "Floor 1",
            'floorPlan': FloorPlanModel.defaultFloorPlan.toJson(),
          },
        ],
        "listeningAreas": [],
        "zones": [],
        "subZones": [],
        "sourceSet": [],
        "circuits": [],
        "wiringConnection": [],
        "hardware": [],
        "fusionDevices": [],
        "suggestedFusionDevices": [],
        "amplifiers": [],
        "processingBlocks": [],
        "relationships": {},
        "zoneFunctions": [],
        "prioritySourceData": [],
        "snapshots": [],
        "sceneActions": [],
        "sceneSets": [],
        "gpioConfig": [],
        "schedulerConfig": [],
        "events": [],
      };

      /// Create the project entity
      final ProjectData newProject = ProjectData(
        id: projectId,
        name: projectDetails.name,
        projectRawData: newProjectData,
        createdAt: now,
        updatedAt: now,
        isCloudInstance: false,
      );

      /// Write the project data to a JSON file
      final File jsonFile = File('${projectDir.path}/$kProjectDataFileName');
      await jsonFile.writeAsString(jsonEncode(newProjectData));

      return ResponseCallback.success(newProject); // Success - no error message
    } catch (e, stack) {
      FusionLogger.log(tag: LogTag.project, message: 'Exception during project creation: $e\n$stack');
      return ResponseCallback.failure('Error creating project: $e');
    }
  }

  ///save all projects to fusion project directory
  Future<ResponseCallback<bool>> saveProjects(List<ProjectData> projects, {bool fromServer = false}) async {
    try {
      final Directory fusionDir = await fusionProjectDirectory;

      for (final ProjectData project in projects) {
        final Directory projectDir = Directory('${fusionDir.path}/${project.id}');

        if (!await projectDir.exists()) {
          await projectDir.create(recursive: true);
        } else {
          if (fromServer) {
            FusionLogger.log(tag: LogTag.project, message: 'Project directory already exists: ${projectDir.path}');
            //check for existing project data file and updated at date to avoid overwriting newer data or if both are same then also skip
            final File existingJsonFile = File('${projectDir.path}/$kProjectDataFileName');
            if (await existingJsonFile.exists()) {
              final String existingJsonStr = await existingJsonFile.readAsString();
              final Map<String, dynamic> existingProjectData = jsonDecode(existingJsonStr);
              final DateTime existingUpdatedAt = DateTime.parse(existingProjectData['updatedAt'] as String);
              if (existingUpdatedAt.isAfter(project.updatedAt) || existingUpdatedAt.isAtSameMomentAs(project.updatedAt)) {
                FusionLogger.log(tag: LogTag.project, message: 'Skipping save for project ${project.id} as existing data is same/newer.');
                continue;
              }
            }
          }
        }

        final File jsonFile = File('${projectDir.path}/$kProjectDataFileName');
        await jsonFile.writeAsString(jsonEncode(project.isCloudInstance ? project.toJson() : project.projectRawData));
      }

      return ResponseCallback.success(true);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'Error saving projects: $e', logLevel: LogLevel.error);
      return ResponseCallback.failure('Error saving projects: $e');
    }
  }

  //import project by zip file and extract to fusion project directory
  Future<ResponseCallback<bool>> importProject(File zipFile) async {
    try {
      final Directory fusionDir = await fusionProjectDirectory;

      // Get zip file name without extension
      final String zipFileName = path.basenameWithoutExtension(zipFile.path);

      // 1. Run extraction in a background isolate to prevent UI freeze
      await compute(_extractZipInBackground, {
        'zipPath': zipFile.path,
        'destinationPath': fusionDir.path,
        'folderName': zipFileName,
      });

      return ResponseCallback.success(true);
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: 'Error importing project: $e',
        logLevel: LogLevel.error,
      );
      return ResponseCallback.failure('Error importing project: $e');
    }
  }

  // 2. This must be a top-level function or a static method
  Future<void> _extractZipInBackground(Map<String, String> params) async {
    final String zipPath = params['zipPath']!;
    final String destinationPath = params['destinationPath']!;
    final String folderName = params['folderName']!;

    try {
      // Create the outer folder with zip file name
      final String projectFolderPath = '$destinationPath/$folderName';
      final projectFolder = Directory(projectFolderPath);

      // Delete if already exists to avoid conflicts
      if (await projectFolder.exists()) {
        await projectFolder.delete(recursive: true);
      }

      await projectFolder.create(recursive: true);

      // Read the zip file
      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Extract files into the project folder
      for (final file in archive) {
        final filename = file.name;
        final filePath = '$projectFolderPath/$filename';

        if (file.isFile) {
          final outFile = File(filePath);
          outFile.createSync(recursive: true);
          outFile.writeAsBytesSync(file.content as List<int>);
        } else {
          Directory(filePath).createSync(recursive: true);
        }
      }

      print("Project extracted to $projectFolderPath from $zipPath");
    } catch (e) {
      print("Error extracting zip: $e");
      rethrow;
    }
  }

  ///save single project to fusion project directory
  Future<ResponseCallback<bool>> saveProject(ProjectData project, {bool fromServer = false}) async {
    try {
      final Directory fusionDir = await fusionProjectDirectory;

      final Directory projectDir = Directory('${fusionDir.path}/${project.id}');

      if (!await projectDir.exists()) {
        await projectDir.create(recursive: true);
      } else {
        if (fromServer) {
          FusionLogger.log(tag: LogTag.project, message: 'Project directory already exists: ${projectDir.path}');
          //check for existing project data file and updated at date to avoid overwriting newer data or if both are same then also skip
          final File existingJsonFile = File('${projectDir.path}/$kProjectDataFileName');
          if (await existingJsonFile.exists()) {
            final String existingJsonStr = await existingJsonFile.readAsString();
            final Map<String, dynamic> existingProjectData = jsonDecode(existingJsonStr);
            final DateTime existingUpdatedAt = DateTime.parse(existingProjectData['updatedAt'] as String);
            if (existingUpdatedAt.isAfter(project.updatedAt) || existingUpdatedAt.isAtSameMomentAs(project.updatedAt)) {
              FusionLogger.log(tag: LogTag.project, message: 'Skipping save for project ${project.id} as existing data is same/newer.');
              return ResponseCallback.success(true);
            }
          }
        }
      }

      final File jsonFile = File('${projectDir.path}/$kProjectDataFileName');
      await jsonFile.writeAsString(jsonEncode(project.isCloudInstance ? project.toJson() : project.projectRawData));

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
  Future<ResponseCallback<bool>> deleteProjectFolder({required String projectId}) async {
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

  Future<String> saveImageToProject({required String imagePath, required String projectId}) async {
    try {
      final Directory fusionDir = await _projectDirectory(projectId);
      final Directory imagesDir = Directory('${fusionDir.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final String imageName = '${DateTime.now().millisecondsSinceEpoch}.png';
      final File imageFile = File('${imagesDir.path}/$imageName');
      await imageFile.writeAsBytes(await File(imagePath).readAsBytes());
      print('Image saved to project successfully: ${imageFile.path}');
      final List<String> splits = fusionDir.path.split("/");
      return "${splits[splits.length - 2]}/${splits.last}/images/$imageName";
    } catch (e) {
      throw ('Error saving image to project: $e');
    }
  }

  Future<String> saveMediaFileToProject({required File mediaFile, required String projectId, String? fileName}) async {
    try {
      final Directory mediaDir = await getProjectMediaDirectory(projectId: projectId);
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }
      fileName ??= path.basename(mediaFile.path);
      final File destFile = File('${mediaDir.path}/$fileName');
      await destFile.writeAsBytes(await mediaFile.readAsBytes());

      return fileName;
    } catch (e) {
      throw ('Error saving media file to project: $e');
    }
  }

  Future<List<File>> getAllMediaFilesFromProject({required String projectId}) async {
    try {
      final Directory mediaDir = await getProjectMediaDirectory(projectId: projectId);
      if (!await mediaDir.exists()) {
        return [];
      }
      final List<FileSystemEntity> entities = await mediaDir.list().toList();
      final List<File> mediaFiles = entities.whereType<File>().toList();
      return mediaFiles;
    } catch (e) {
      throw ('Error getting media files from project: $e');
    }
  }

  Future<void> deleteMediaFileFromProject({required String projectId, required String fileName}) async {
    try {
      final Directory mediaDir = await getProjectMediaDirectory(projectId: projectId);
      final File mediaFile = File('${mediaDir.path}/$fileName');
      if (await mediaFile.exists()) {
        await mediaFile.delete();
      } else {
        FusionLogger.log(tag: LogTag.project, message: 'Media file does not exist: ${mediaFile.path}');
      }
    } catch (e) {
      throw ('Error deleting media file from project: $e');
    }
  }

  Future<void> renameMediaFileInProject({required String projectId, required String oldFileName, required String newFileName}) async {
    try {
      final Directory mediaDir = await getProjectMediaDirectory(projectId: projectId);
      final File oldMediaFile = File('${mediaDir.path}/$oldFileName');
      final File newMediaFile = File('${mediaDir.path}/$newFileName');
      if (await oldMediaFile.exists()) {
        await oldMediaFile.rename(newMediaFile.path);
      } else {
        throw ('Media file does not exist: ${oldMediaFile.path}');
      }
    } catch (e) {
      throw ('Error renaming media file in project: $e');
    }
  }

  Future<String> saveAssetImageToProject({required String assetPath, required String projectId}) async {
    try {
      final Directory fusionDir = await _projectDirectory(projectId);
      final Directory imagesDir = Directory('${fusionDir.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final String imageName = '${DateTime.now().millisecondsSinceEpoch}.png';
      final File imageFile = File('${imagesDir.path}/$imageName');
      final ByteData data = await rootBundle.load(assetPath);
      await imageFile.writeAsBytes(data.buffer.asUint8List());
      print('Asset image saved to project successfully: ${imageFile.path}');
      final List<String> splits = fusionDir.path.split("/");
      return "${splits[splits.length - 2]}/${splits.last}/images/$imageName";
    } catch (e) {
      throw ('Error saving asset image to project: $e');
    }
  }

  Future<File> getImageFromProject({required String imageName, required String projectId}) async {
    try {
      final Directory fusionDir = await _projectDirectory(projectId);
      final Directory imagesDir = Directory('${fusionDir.path}/images');
      if (!await imagesDir.exists()) {
        throw ('Images directory does not exist');
      }
      final File imageFile = File('${imagesDir.path}/$imageName');
      if (!await imageFile.exists()) {
        throw ('Image file does not exist: ${imageFile.path}');
      }
      return imageFile;
    } catch (e) {
      throw ('Error getting image from project: $e');
    }
  }

  Future<Directory> _projectDirectory(String projectId) async {
    final Directory fusionDir = await fusionProjectDirectory;
    final Directory projectDir = Directory('${fusionDir.path}/$projectId');
    if (!await projectDir.exists()) {
      await projectDir.create(recursive: true);
    }
    return projectDir;
  }
}
