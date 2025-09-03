import '../../fusion_lib.dart';

class ProjectCloudSyncManager {
  final FusionNetworkClient networkClient;
  final LocalProjectManager localProjectManager;
  ProjectCloudSyncManager({required this.networkClient, required this.localProjectManager});

  Future<ResponseCallback<List<ProjectData>?>> loadProjects() async {
    try {
      final ResponseCallback<List<ProjectData>?> response = await networkClient.get(
        api: FusionApiEndpoint.projects,
        fromJson: (data) => (data as List<dynamic>).map((json) => ProjectData.fromJson(json as Map<String, dynamic>)).toList(),
      );

      if (response.success && response.data != null) {
        //SAve to Local folder
        await localProjectManager.saveProjects(response.data!);
      }
      return response;
    } catch (e) {
      return ResponseCallback.failure("Error loading projects: $e");
    }
  }

  //sync projects to cloud
  Future<ResponseCallback<bool>> syncProjectsToCloud(List<ProjectData> projects) async {
    try {
      // Sync each project & its associated data

      return ResponseCallback.success(true);
    } catch (e) {
      return ResponseCallback.failure("Error syncing projects: $e");
    }
  }

  //sync a single project to cloud
  Future<ResponseCallback<bool>> syncProjectToCloud(ProjectData project) async {
    try {
      // Sync the project & its associated data

      return ResponseCallback.success(true);
    } catch (e) {
      return ResponseCallback.failure("Error syncing project: $e");
    }
  }
}
