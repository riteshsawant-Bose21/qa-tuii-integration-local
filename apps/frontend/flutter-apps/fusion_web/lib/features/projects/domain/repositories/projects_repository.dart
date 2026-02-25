import 'package:fusion_web/features/projects/data/models/project_model.dart';

// Repository interface - Domain layer doesn't know about implementation
abstract class ProjectsRepository {
  Future<List<ProjectModel>> getProjects();
  Future<ProjectModel> getProjectById(String id);
  Future<ProjectModel> createProject(ProjectModel project);
  Future<ProjectModel> updateProject(ProjectModel project);
  Future<void> deleteProject(String id);
  Future<List<ProjectModel>> searchProjects(String query);
}
