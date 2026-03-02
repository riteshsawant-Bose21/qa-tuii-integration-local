import 'package:fusion_web/features/projects/data/models/project_model.dart';

// Repository interface - Domain layer doesn't know about implementation
abstract class ProjectsRepository {
  Future<List<ProjectModel>> getProjects();
  Future<ProjectModel> getProjectById(String id);
  Future<void> deleteProject(String id);
  Future<void> archiveProject(String id);
  Future<List<ProjectModel>> searchProjects(String query);
}
