import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/models/project_entity.dart';
import '../../../../core/utils/shared_preference_handler.dart';
import 'project_local_datasource.dart';

class ProjectLocalDataSourceImpl implements ProjectLocalDataSource {
  final SharedPreferencesHandler prefs;

  ProjectLocalDataSourceImpl({required this.prefs});

  @override
  Future<void> saveProject(ProjectEntity project) async {
    final File file = await _localFile(project.name);
    final String jsonStr = jsonEncode(project.toJson());
    await file.writeAsString(jsonStr);
  }

  @override
  Future<ProjectEntity> loadProject(String projectName) async {
    final File file = await _localFile(projectName);
    if (!await file.exists()) {
      throw Exception('Project file not found');
    }
    final String jsonStr = await file.readAsString();
    final Map<String, dynamic> map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return ProjectEntity.fromJson(map);
  }

  @override
  Future<void> deleteProject(String projectName) async {
    final File file = await _localFile(projectName);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<String> saveImageToProject(String projectName, String imagePath) async {
    final Directory fusionDir = await _projectDirectory(projectName);
    final Directory imagesDir = Directory('${fusionDir.path}/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final String imageName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final File imageFile = File('${imagesDir.path}/$imageName');
    await imageFile.writeAsBytes(await File(imagePath).readAsBytes());
    final List<String> splits = fusionDir.path.split("/");
    return "${splits[splits.length - 2]}/${splits.last}/images/$imageName";
  }

  @override
  Future<String> saveAssetImageToProject(String projectName, String assetPath) async {
    final Directory fusionDir = await _projectDirectory(projectName);
    final Directory imagesDir = Directory('${fusionDir.path}/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final String imageName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final File imageFile = File('${imagesDir.path}/$imageName');
    final ByteData data = await rootBundle.load(assetPath);
    await imageFile.writeAsBytes(data.buffer.asUint8List());
    final List<String> splits = fusionDir.path.split("/");
    return "${splits[splits.length - 2]}/${splits.last}/images/$imageName";
  }

  @override
  Future<File> getImageFromProject(String projectName, String imageName) async {
    final Directory fusionDir = await _projectDirectory(projectName);
    final Directory imagesDir = Directory('${fusionDir.path}/images');
    if (!await imagesDir.exists()) {
      throw Exception('Images directory does not exist');
    }
    final File imageFile = File('${imagesDir.path}/$imageName');
    if (!await imageFile.exists()) {
      throw Exception('Image file does not exist: ${imageFile.path}');
    }
    return imageFile;
  }

  Future<Directory> _projectDirectory(String projectName) async {
    final bool adminLogin = prefs.getBool(SharedPreferenceKeys.adminLogin) ?? false;
    final String fusionDirPath = adminLogin ? '/AdminFusionProject' : '/FusionProject';
    final Directory dir = await getApplicationDocumentsDirectory();
    final Directory projectDir = Directory('${dir.path}$fusionDirPath/$projectName');

    if (!await projectDir.exists()) {
      await projectDir.create(recursive: true);
    }

    return projectDir;
  }

  Future<File> _localFile(String projectName) async {
    final bool adminLogin = prefs.getBool(SharedPreferenceKeys.adminLogin) ?? false;
    final String fusionDirPath = adminLogin ? '/AdminFusionProject' : '/FusionProject';
    final Directory dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fusionDirPath/$projectName/project_data.json');
  }
}
