import 'package:fusion_web/features/projects/data/models/project_model.dart';
import 'package:fusion_web/core/services/api_service.dart';

abstract class ProjectsDataSource {
  Future<List<ProjectModel>> getProjects();
  Future<ProjectModel> getProjectById(String id);
  Future<ProjectModel> createProject(ProjectModel project);
  Future<ProjectModel> updateProject(ProjectModel project);
  Future<void> deleteProject(String id);
  Future<List<ProjectModel>> searchProjects(String query);
}

class ProjectsRemoteDataSource implements ProjectsDataSource {
  final ApiService _apiService;

  ProjectsRemoteDataSource({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  @override
  Future<List<ProjectModel>> getProjects() async {
    try {
      print('Projects API: Calling /projects endpoint');
      final response = await _apiService.get('/projects?is_archived=false');

      // Debug: Print the full response structure
      print('API Response keys: ${response.keys.toList()}');
      print('API Response: $response');

      final projectsJson =
          response['data'] as List<dynamic>? ??
          response['projects'] as List<dynamic>? ??
          response['items'] as List<dynamic>? ??
          [];

      print('Projects array length: ${projectsJson.length}');

      if (projectsJson.isNotEmpty) {
        print('First project sample: ${projectsJson.first}');
      }

      return projectsJson
          .map((json) {
            try {
              return ProjectModel.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              print('Error parsing project: $json, Error: $e');
              return null;
            }
          })
          .where((project) => project != null)
          .cast<ProjectModel>()
          .toList();
    } catch (e) {
      print('REAL API ERROR: $e');
      rethrow;

      // } catch (e) {
      //   // Fallback to mock data if API fails
      //   print('API Error, using mock data: $e');
      //   return ProjectModel.mockProjects();
    }
  }

  @override
  Future<ProjectModel> getProjectById(String id) async {
    try {
      final response = await _apiService.get('/projects/$id');
      final projectData =
          response['data'] as Map<String, dynamic>? ??
          response['project'] as Map<String, dynamic>? ??
          response;

      return ProjectModel.fromJson(projectData);
    } catch (e) {
      // Fallback to mock data if API fails
      print('API Error, using mock data: $e');
      final projects = ProjectModel.mockProjects();
      return projects.firstWhere((p) => p.id == id);
    }
  }

  @override
  Future<ProjectModel> createProject(ProjectModel project) async {
    try {
      final response = await _apiService.post('projects', project.toJson());

      print('Create response: $response');

      final projectData =
          response['data'] as Map<String, dynamic>? ??
          response['project'] as Map<String, dynamic>? ??
          response;

      return ProjectModel.fromJson(projectData);
    } catch (e) {
      print('CREATE PROJECT API ERROR: $e');
      rethrow;
    }
  }

  @override
  Future<ProjectModel> updateProject(ProjectModel project) async {
    try {
      final response = await _apiService.patch(
        'projects/${project.id}',
        project.toJson(),
      );
      final projectData =
          response['data'] as Map<String, dynamic>? ??
          response['project'] as Map<String, dynamic>? ??
          response;

      return ProjectModel.fromJson(projectData);
    } catch (e) {
      // Fallback behavior - return the project as-is for demo
      print('API Error, simulating update: $e');
      await Future.delayed(const Duration(milliseconds: 600));
      return project;
    }
  }

  @override
  Future<void> deleteProject(String id) async {
    try {
      await _apiService.delete('projects/$id');
    } catch (e) {
      // Fallback behavior - simulate success for demo
      print('API Error, simulating deletion: $e');
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  //search implementation when backend is 
  
  // @override
  // Future<List<ProjectModel>> searchProjects(String query) async {
  //   try {
  //     final response = await _apiService.get(
  //       '/projects/search?q=${Uri.encodeComponent(query)}',
  //     );

  //         final projectsJson =
  //           response['data'] as List<dynamic>? ??
  //           response['projects'] as List<dynamic>? ??
  //           [];

  //       return projectsJson
  //           .map((json) => ProjectModel.fromJson(json as Map<String, dynamic>))
  //           .toList();
  //     } catch (e) {
  //       // Fallback to local search on mock data
  //       print('API Error, using mock search: $e');
  //       final projects = ProjectModel.mockProjects();
  //       return projects
  //           .where(
  //             (p) =>
  //                 p.name.toLowerCase().contains(query.toLowerCase()) ||
  //                 p.description.toLowerCase().contains(query.toLowerCase()) ||
  //                 (p.clientName?.toLowerCase().contains(query.toLowerCase()) ??
  //                     false),
  //           )
  //           .toList();
  //     }
  //   }
  // }

  //below is the temporary search implementation until backend is ready
  @override
  Future<List<ProjectModel>> searchProjects(String query) async {
    final allProjects = await getProjects();

    return allProjects
        .where(
          (p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              p.description.toLowerCase().contains(query.toLowerCase()) ||
              (p.clientName?.toLowerCase().contains(query.toLowerCase()) ??
                  false),
        )
        .toList();
  }
}
//above is the temporary search implementation until backend is ready 
class ProjectsLocalDataSource implements ProjectsDataSource {
  List<ProjectModel>? _cachedProjects;

  @override
  Future<List<ProjectModel>> getProjects() async {
    if (_cachedProjects != null) {
      return _cachedProjects!;
    }
    throw Exception('No cached projects available');
  }

//temporary implementation until backend is ready - getProjectByID
  @override
  Future<ProjectModel> getProjectById(String id) async {
    if (_cachedProjects != null) {
      return _cachedProjects!.firstWhere((p) => p.id == id);
    }
    throw Exception('No cached projects available');
  }

  //when backend is ready use this instead
  // @override
  // Future<ProjectModel> getProjectById(String id) async {
  //   try {
  //     // Try real endpoint first (when backend is ready later)
  //     return await remoteDataSource.getProjectById(id);
  //   } catch (_) {
  //     // TEMPORARY: use list endpoint and filter
  //     final projects = await remoteDataSource.getProjects();
  //     return projects.firstWhere((p) => p.id == id);
  //   }
  // }

  @override
  Future<ProjectModel> createProject(ProjectModel project) async {
    _cachedProjects ??= [];
    _cachedProjects!.add(project);
    return project;
  }

  @override
  Future<ProjectModel> updateProject(ProjectModel project) async {
    if (_cachedProjects != null) {
      final index = _cachedProjects!.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        _cachedProjects![index] = project;
      }
    }
    return project;
  }

  @override
  Future<void> deleteProject(String id) async {
    _cachedProjects?.removeWhere((p) => p.id == id);
  }

  @override
  Future<List<ProjectModel>> searchProjects(String query) async {
    if (_cachedProjects != null) {
      return _cachedProjects!
          .where(
            (p) =>
                p.name.toLowerCase().contains(query.toLowerCase()) ||
                p.description.toLowerCase().contains(query.toLowerCase()) ||
                (p.clientName?.toLowerCase().contains(query.toLowerCase()) ??
                    false),
          )
          .toList();
    }
    throw Exception('No cached projects available');
  }

  void cacheProjects(List<ProjectModel> projects) {
    _cachedProjects = projects;
  }
}
