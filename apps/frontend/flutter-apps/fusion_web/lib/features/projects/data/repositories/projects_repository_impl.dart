import 'package:fusion_web/features/projects/data/datasources/project_datasource.dart';
import 'package:fusion_web/features/projects/data/models/project_model.dart';
import 'package:fusion_web/features/projects/data/repositories/projects_repository.dart';
import 'package:fusion_web/features/users/data/models/user_model.dart';

class ProjectsRepositoryImpl implements ProjectsRepository {
  final ProjectsRemoteDataSource remoteDataSource;

  ProjectsRepositoryImpl({
    required this.remoteDataSource,
  });

  // =========================
  // GET ALL PROJECTS
  // =========================
  @override
  Future<List<ProjectModel>> getProjects() async {
    try {
      final remoteData = await remoteDataSource.getProjects();
      return remoteData;
    } catch (e) {
      rethrow; // do NOT fallback to empty local cache
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
  //     rethrow;
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
  }

  // =========================
  // ARCHIVE PROJECT
  // =========================
  @override
  Future<void> archiveProject(String id) async {
    await remoteDataSource.archiveProject(id);
  }

  // =========================
  // FILTER PROJECTS
  // =========================
  @override
  Future<List<ProjectModel>> getProjectsFiltered({
    String? search,
    String? region,
    String? status,
  }) async {
    final projects = await remoteDataSource.getProjects(); // always fresh

    return projects.where((p) {
      final searchMatch =
          search == null ||
          search.isEmpty ||
          p.name.toLowerCase().contains(search.toLowerCase());

      final regionMatch =
          region == null || region == 'All' || p.region == region;

      final statusMatch =
          status == null || status == 'All' || p.status == status;

      return searchMatch && regionMatch && statusMatch;
    }).toList();
  }


  // =========================
  // USERS
  // =========================
  @override
  Future<List<UserModel>> getOrganisationUsers() async {
    return await remoteDataSource.getOrganisationUsers();
  }

  @override
  Future<void> addUserToProject({
    required String projectId,
    required String userEmail,
  }) async {
    await remoteDataSource.addUserToProject(
      projectId: projectId,
      userEmail: userEmail,
    );
  }
}
