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

  //Open / Load project by ID
  Future<ResponseCallback<ProjectData>> openProjectById(String projectId) async {
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


}
