import 'package:fusion_web/features/projects/data/models/project_model.dart';
import 'package:fusion_web/features/users/data/models/user_model.dart';

// Repository interface - Domain layer doesn't know about implementation
abstract class ProjectsRepository {
  Future<List<ProjectModel>> getProjects();
  Future<ProjectModel> getProjectById(String id);
  Future<void> deleteProject(String id);
  Future<void> archiveProject(String id);
  Future<List<ProjectModel>> searchProjects(String query);
  Future<List<ProjectModel>> filterProjects({String? region, String? status});
  //fetchign all users and adding user to project
  Future<List<UserModel>> getOrganisationUsers();
  Future<void> addUserToProject({
    required String projectId,
    required String userEmail,
  });
}
