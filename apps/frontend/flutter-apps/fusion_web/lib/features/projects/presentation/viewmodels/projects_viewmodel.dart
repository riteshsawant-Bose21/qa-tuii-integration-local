import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:fusion_web/core/usecases/usecase.dart';
import 'package:fusion_web/features/projects/domain/entities/project_entity.dart';
import 'package:fusion_web/features/projects/domain/usecases/projects_usecases.dart';

class ProjectsViewModel extends BaseViewModel {
  final GetProjectsUseCase getProjectsUseCase;
  final GetProjectByIdUseCase getProjectByIdUseCase;
  final CreateProjectUseCase createProjectUseCase;
  final UpdateProjectUseCase updateProjectUseCase;
  final DeleteProjectUseCase deleteProjectUseCase;
  final SearchProjectsUseCase searchProjectsUseCase;

  List<ProjectEntity> _projects = [];
  List<ProjectEntity> _filteredProjects = [];
  ProjectEntity? _selectedProject;
  String _searchQuery = '';

  ProjectsViewModel({
    required this.getProjectsUseCase,
    required this.getProjectByIdUseCase,
    required this.createProjectUseCase,
    required this.updateProjectUseCase,
    required this.deleteProjectUseCase,
    required this.searchProjectsUseCase,
  });

  List<ProjectEntity> get projects {
    if (_filteredProjects.isNotEmpty) {
      return _filteredProjects;
    }
    return _projects;
  }

  ProjectEntity? get selectedProject => _selectedProject;
  String get searchQuery => _searchQuery;

  Future<void> loadProjects() async {
    try {
      setLoading();
      final projects = await getProjectsUseCase(const NoParams());
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
      final results = await searchProjectsUseCase(query);
      _filteredProjects = results;
      notifyListeners();
    } catch (e) {
      _filteredProjects = _projects
          .where(
            (p) =>
                p.title.toLowerCase().contains(query.toLowerCase()) ||
                p.description.toLowerCase().contains(query.toLowerCase()) ||
                (p.clientName?.toLowerCase().contains(query.toLowerCase()) ?? false),          )
          .toList();
      notifyListeners();
    }
  }

  Future<void> getProject(String id) async {
    try {
      setLoading();
      final project = await getProjectByIdUseCase(id);
      _selectedProject = project;
      setLoaded(project);
    } catch (e) {
      setError('Failed to load project: ${e.toString()}');
    }
  }

  Future<void> createProject(ProjectEntity project) async {
    try {
      setLoading();
      await createProjectUseCase(project);
      await loadProjects();
    } catch (e) {
      setError('Failed to create project: ${e.toString()}');
    }
  }

  Future<void> updateProject(ProjectEntity project) async {
    try {
      setLoading();
      await updateProjectUseCase(project);
      await loadProjects();
    } catch (e) {
      setError('Failed to update project: ${e.toString()}');
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      setLoading();
      await deleteProjectUseCase(id);
      await loadProjects();
    } catch (e) {
      setError('Failed to delete project: ${e.toString()}');
    }
  }

  void initialize() {
    loadProjects();
  }

  void selectProject(ProjectEntity project) {
    _selectedProject = project;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredProjects = [];
    notifyListeners();
  }
}
