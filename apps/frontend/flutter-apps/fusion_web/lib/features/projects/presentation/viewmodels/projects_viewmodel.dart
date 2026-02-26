import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:fusion_web/core/usecases/usecase.dart';
import 'package:fusion_web/features/projects/data/models/project_model.dart';
import 'package:fusion_web/features/projects/data/repositories/projects_repository.dart';

class ProjectsViewModel extends BaseViewModel {
  final ProjectsRepository repository;

  ProjectsViewModel({required this.repository});

  List<ProjectModel> _projects = [];
  List<ProjectModel> _filteredProjects = [];
  ProjectModel? _selectedProject;
  String _searchQuery = '';

  List<ProjectModel> get projects {
    if (_filteredProjects.isNotEmpty) {
      return _filteredProjects;
    }
    return _projects;
  }

  ProjectModel? get selectedProject => _selectedProject;
  String get searchQuery => _searchQuery;

  Future<void> loadProjects() async {
    try {
      setLoading();
      final projects = await repository.getProjects();
      _projects = projects;
      _filteredProjects = [];
      setLoaded(projects);
    } catch (e) {
      _projects = [];
      _filteredProjects = [];
      setError('Failed to load projects: ${e.toString()}');
    }
  }

  Future<void> searchProjects(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredProjects = [];
      notifyListeners();
      return;
    }

    try {
      final results = await repository.searchProjects(query);
      _filteredProjects = results;
      notifyListeners();
    } catch (e) {
      _filteredProjects = _projects
          .where(
            (p) =>
                p.name.toLowerCase().contains(query.toLowerCase()) ||
                p.description.toLowerCase().contains(query.toLowerCase()) ||
                (p.clientName?.toLowerCase().contains(query.toLowerCase()) ??
                    false),
          )
          .toList();
      notifyListeners();
    }
  }

  Future<void> getProject(String id) async {
    try {
      setLoading();

      final project = await repository.getProjectById(id);

      _selectedProject = project;
      setLoaded(project);
    } catch (e) {
      setError('Failed to load project');
    }
  }

  Future<void> createProject(ProjectModel project) async {
    print("🔥 VIEWMODEL CREATE CALLED");
    try {
      setLoading();
      await repository.createProject(project);
      print("🔥 CREATE API FINISHED");
      await loadProjects();
    } catch (e) {
      print("🔥 CREATE ERROR: $e");
      setError('Failed to create project: ${e.toString()}');
    }
  }

  Future<void> updateProject(ProjectModel project) async {
    try {
      setLoading();
      await repository.updateProject(project);
      await loadProjects();
    } catch (e) {
      setError('Failed to update project: ${e.toString()}');
    }
  }

  Future<void> deleteProject(String id) async {
  try {
    await repository.deleteProject(id);

    _projects.removeWhere((p) => p.id == id);
    _filteredProjects.removeWhere((p) => p.id == id);

    notifyListeners();
    
  } catch (e) {
    setError('Failed to delete project');
  }
}

  void initialize() {
    loadProjects();
  }

  void selectProject(ProjectModel project) {
    _selectedProject = project;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredProjects = [];
    notifyListeners();
  }
}
