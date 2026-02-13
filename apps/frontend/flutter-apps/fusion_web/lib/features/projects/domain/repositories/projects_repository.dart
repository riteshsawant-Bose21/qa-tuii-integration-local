import 'package:fusion_web/features/projects/domain/entities/project_entity.dart';
// import 'package:fusion_web/features/projects/presentation/pages/projects_page.dart';

// Repository interface - Domain layer doesn't know about implementation
abstract class ProjectsRepository {
  Future<List<ProjectEntity>> getProjects();
  Future<ProjectEntity> getProjectById(String id);
  Future<ProjectEntity> createProject(ProjectEntity project);
  Future<ProjectEntity> updateProject(ProjectEntity project);
  Future<void> deleteProject(String id);
  Future<List<ProjectEntity>> searchProjects(String query);
}
