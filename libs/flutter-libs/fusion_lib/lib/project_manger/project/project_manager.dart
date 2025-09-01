import 'dart:io';

import '../../fusion_lib.dart';

class ProjectManager {
  final ProjectCloudSyncManager projectCloudSyncManager;
  final LocalProjectManager localProjectManager;

  static List<ProjectData> projects = [];

  ProjectService? projectService;

  ProjectManager({required this.projectCloudSyncManager, required this.localProjectManager});

  /// Get project by ID
  /// Throws StateError if not found
  static ProjectData getProjectById(String projectId) {
    return projects.firstWhere((project) => project.id == projectId);
  }

  /// check if Admin login
  bool isAdminLogin() {
    return localProjectManager.isAdminLogin;
  }

  //Load projects from cloud
  Future<ResponseCallback<List<ProjectData>?>> loadProjectsFromCloud() async {
    final ResponseCallback<List<ProjectData>?> response = await projectCloudSyncManager.loadProjects();
    if (response.success && response.data != null) {
      projects = response.data!;
    }
    return response;
  }

  //Load projects from local storage
  Future<ResponseCallback<List<ProjectData>>> loadProjectsFromLocal() async {
    final ResponseCallback<List<ProjectData>> response = await localProjectManager.loadProjects();
    if (response.success && response.data != null) {
      projects = response.data!;
    }
    return response;
  }

  // Create and save new project
  Future<ResponseCallback<ProjectData?>> createAndSaveNewProject(NewProjectDetails newProject) async {
    try {
      ResponseCallback<ProjectData?> createProjectResponse = await localProjectManager.createNewProject(projectDetails: newProject);

      if (createProjectResponse.success && createProjectResponse.data != null) {
        projects.add(createProjectResponse.data!);
      }
      return createProjectResponse;
    } catch (e) {
      return ResponseCallback.failure("Error creating and saving new project: $e");
    }
  }

  //Delete all projects
  Future<ResponseCallback<bool>> deleteFusionProjectsDirectory() async {
    try {
      await localProjectManager.deleteFusionProjectDirectory();
      projects.clear();
      projectService = null;
      return ResponseCallback.success(true);
    } catch (e) {
      return ResponseCallback.failure("Error deleting Fusion directory: $e");
    }
  }

  //Delete specific project by ID
  Future<ResponseCallback<bool>> deleteProject(String projectId) async {
    try {
      await localProjectManager.deleteProject(projectId: projectId);
      projects.removeWhere((p) => p.id == projectId);
      if (projectService != null && projectService!.id == projectId) {
        projectService = null;
      }
      return ResponseCallback.success(true);
    } catch (e) {
      return ResponseCallback.failure("Error deleting project: $e");
    }
  }

  //Open / Load project by ID
  ResponseCallback<ProjectData> openProjectById(String projectId) {
    try {
      final ProjectData project = getProjectById(projectId);
      projectService = ProjectService.fromJson(project.projectRawData);

      return ResponseCallback.success(project);
    } catch (e) {
      return ResponseCallback.failure("Error opening project: $e");
    }
  }

  //Save current project
  Future<ResponseCallback<bool>> saveCurrentProject() async {
    if (projectService == null) {
      return ResponseCallback.failure("No project is currently loaded.");
    }

    // Record the change before saving (for undo/redo functionality)
    // We can add this before every change to the projectService to support step by step undo/redo
    projectService!.recordChange();

    try {
      final ProjectData currentProject = getProjectById(projectService!.id);
      final ProjectData updatedProject = currentProject.copyWith(projectRawData: projectService!.toJson());

      // Save to local storage
      await localProjectManager.saveProject(updatedProject);

      return ResponseCallback.success(true);
    } catch (e) {
      return ResponseCallback.failure("Error saving project: $e");
    }
  }

  /// save image to current project directory
  Future<ResponseCallback<String>> saveImageToCurrentProject(String imagePath) async {
    if (projectService == null) {
      return ResponseCallback.failure("No project is currently loaded.");
    }
    try {
      final String savedImagePath = await localProjectManager.saveImageToProject(projectId: projectService!.id, imagePath: imagePath);
      return ResponseCallback.success(savedImagePath);
    } catch (e) {
      return ResponseCallback.failure("Error saving image to project directory: $e");
    }
  }

  /// save asset Image to current project directory
  Future<ResponseCallback<String>> saveAssetImageToCurrentProject(String assetPath) async {
    if (projectService == null) {
      return ResponseCallback.failure("No project is currently loaded.");
    }
    try {
      final String savedImagePath = await localProjectManager.saveAssetImageToProject(projectId: projectService!.id, assetPath: assetPath);
      return ResponseCallback.success(savedImagePath);
    } catch (e) {
      return ResponseCallback.failure("Error saving image to project directory: $e");
    }
  }

  /// get image
  Future<ResponseCallback<File>> getImageFromCurrentProject(String imageName) async {
    if (projectService == null) {
      return ResponseCallback.failure("No project is currently loaded.");
    }
    try {
      final File file = await localProjectManager.getImageFromProject(projectId: projectService!.id, imageName: imageName);
      return ResponseCallback.success(file);
    } catch (e) {
      return ResponseCallback.failure("Error getting image from project directory: $e");
    }
  }

  // get Project JSon
  Map<String, dynamic> getCurrentProjectJson() {
    return projectService?.toJson() ?? {};
  }
}
