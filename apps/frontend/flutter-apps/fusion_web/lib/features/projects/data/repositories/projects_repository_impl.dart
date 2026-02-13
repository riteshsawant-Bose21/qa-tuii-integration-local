import 'package:fusion_web/features/projects/data/datasources/project_datasource.dart';
import 'package:fusion_web/features/projects/data/models/project_model.dart';
import 'package:fusion_web/features/projects/domain/entities/project_entity.dart';
import 'package:fusion_web/features/projects/domain/repositories/projects_repository.dart';

class ProjectsRepositoryImpl implements ProjectsRepository {
  final ProjectsRemoteDataSource remoteDataSource;
  final ProjectsLocalDataSource localDataSource;

  const ProjectsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<ProjectEntity>> getProjects() async {
    try {
      final remoteData = await remoteDataSource.getProjects();
      localDataSource.cacheProjects(remoteData);
      return remoteData;
    } catch (_) {
      try {
        return await localDataSource.getProjects();
      } catch (_) {
        return ProjectModel.mockProjects();
      }
    }
  }

  @override
  Future<ProjectEntity> getProjectById(String id) async {
    try {
      return await remoteDataSource.getProjectById(id);
    } catch (_) {
      try {
        return await localDataSource.getProjectById(id);
      } catch (_) {
        return ProjectModel.mockProjects().first;
      }
    }
  }

  @override
  Future<ProjectEntity> createProject(ProjectEntity project) async {
    final projectModel = ProjectModel(
      id: project.id,
      title: project.title,
      description: project.description,
      clientName: project.clientName,
      region: project.region,
      status: project.status,
      healthyDevices: project.healthyDevices,
      warningDevices: project.warningDevices,
      criticalDevices: project.criticalDevices,
      incidents: project.incidents,
      lastUpdated: project.lastUpdated,
    );

    try {
      final result = await remoteDataSource.createProject(projectModel);
      await localDataSource.createProject(result);
      return result;
    } catch (_) {
      return await localDataSource.createProject(projectModel);
    }
  }

  @override
  Future<ProjectEntity> updateProject(ProjectEntity project) async {
    final projectModel = ProjectModel(
      id: project.id,
      title: project.title,
      description: project.description,
      clientName: project.clientName,
      region: project.region,
      status: project.status,
      healthyDevices: project.healthyDevices,
      warningDevices: project.warningDevices,
      criticalDevices: project.criticalDevices,
      incidents: project.incidents,
      lastUpdated: project.lastUpdated,
    );

    try {
      final result = await remoteDataSource.updateProject(projectModel);
      await localDataSource.updateProject(result);
      return result;
    } catch (_) {
      return await localDataSource.updateProject(projectModel);
    }
  }

  @override
  Future<void> deleteProject(String id) async {
    try {
      await remoteDataSource.deleteProject(id);
      await localDataSource.deleteProject(id);
    } catch (_) {
      await localDataSource.deleteProject(id);
    }
  }

  @override
  Future<List<ProjectEntity>> searchProjects(String query) async {
    try {
      return await remoteDataSource.searchProjects(query);
    } catch (_) {
      try {
        return await localDataSource.searchProjects(query);
      } catch (_) {
        final projects = ProjectModel.mockProjects();

        return projects.where((p) {
          return p.title.toLowerCase().contains(query.toLowerCase()) ||
              p.description.toLowerCase().contains(query.toLowerCase()) ||
              p.clientName.toLowerCase().contains(query.toLowerCase()) ||
              p.region.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    }
  }
}
