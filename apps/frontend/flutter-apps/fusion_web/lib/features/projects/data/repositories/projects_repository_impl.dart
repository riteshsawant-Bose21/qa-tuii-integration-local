import 'package:fusion_web/features/projects/data/datasources/project_datasource.dart';
import 'package:fusion_web/features/projects/data/models/project_model.dart';
import 'package:fusion_web/features/projects/data/repositories/projects_repository.dart';

class ProjectsRepositoryImpl implements ProjectsRepository {
  final ProjectsRemoteDataSource remoteDataSource;
  final ProjectsLocalDataSource localDataSource;

  const ProjectsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  // =========================
  // GET ALL PROJECTS
  // =========================
  @override
  Future<List<ProjectModel>> getProjects() async {
    try {
      final remoteData = await remoteDataSource.getProjects();
      localDataSource.cacheProjects(remoteData);
      return remoteData;
    } catch (e) {
      // Try local cache if remote fails
      return await localDataSource.getProjects();
    }
  }

  // =========================
  // GET PROJECT BY ID
  // =========================
  // @override
  // Future<ProjectModel> getProjectById(String id) async {
  //   try {
  //     return await remoteDataSource.getProjectById(id);
  //   } catch (e) {
  //     return await localDataSource.getProjectById(id);
  //   }
  // }
  @override
  Future<ProjectModel> getProjectById(String id) async {
    try {
      // Try real endpoint first (when backend is ready later)
      return await remoteDataSource.getProjectById(id);
    } catch (_) {
      // TEMP: use working list API and filter
      final projects = await remoteDataSource.getProjects();
      return projects.firstWhere((p) => p.id == id);
    }
  }

  // =========================
  // DELETE PROJECT
  // =========================
  @override
  Future<void> deleteProject(String id) async {
    await remoteDataSource.deleteProject(id);
    await localDataSource.deleteProject(id);
  }


  // =========================
  // ARCHIVE PROJECT
  // =========================
  @override
  Future<void> archiveProject(String id) async {
    await remoteDataSource.archiveProject(id);
    await localDataSource.archiveProject(id);
  }

  // =========================
  // SEARCH PROJECTS
  // =========================
  @override
  Future<List<ProjectModel>> searchProjects(String query) async {
    return await remoteDataSource.searchProjects(query);
  }
}
