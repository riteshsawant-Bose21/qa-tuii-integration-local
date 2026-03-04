// import 'package:fusion_web/core/presentation/base_viewmodel.dart';
// import 'package:fusion_web/features/projects/data/models/project_model.dart';
// import 'package:fusion_web/features/projects/data/repositories/projects_repository.dart';

// class ProjectsViewModel extends BaseViewModel<List<ProjectModel>> {
//   final ProjectsRepository repository;

//   ProjectsViewModel({required this.repository});

//   final List<ProjectModel> _projects = [];

//   ProjectModel? _selectedProject;
//   final String _searchQuery = '';

//   ProjectModel? get selectedProject => _selectedProject;
//   String get searchQuery => _searchQuery;

//   // Future<void> loadProjects({String? searchQuery}) async {
//   //   try {
//   //     setLoading();
//   //     final projects = searchQuery != null && searchQuery.isNotEmpty
//   //         ? await repository.searchProjects(searchQuery)
//   //         : await repository.getProjects();

//   //     setLoaded(projects);
//   //   } catch (e) {
//   //     setError('Failed to load projects: ${e.toString()}');
//   //   }
//   // }
//   //
//   Future<void> loadProjects() async {
//     try {
//       setLoading();

//       final projects = await repository.getProjects();

//       _projects.clear();
//       _projects.addAll(projects);

//       setLoaded(projects);
//     } catch (e) {
//       setError('Failed to load projects: ${e.toString()}');
//     }
//   }

//   Future<void> searchProjects(String query) async {
//     if (query.isEmpty) {
//       setLoaded(_projects);
//       return;
//     }

//     final filtered = _projects.where((project) {
//       return project.name.toLowerCase().contains(query.toLowerCase());
//     }).toList();

//     setLoaded(filtered);
//   }

//   Future<void> getProject(String id) async {
//     // try {
//     //   setLoading();

//     //   final project = await repository.getProjectById(id);

//     //   setLoaded(project);
//     // } catch (e) {
//     //   setError('Failed to load project');
//     // }
//   }

// Future<void> deleteProject(String id) async {
//   try {
//     await repository.deleteProject(id);

//     _projects.removeWhere((p) => p.id == id);

//     setLoaded(_projects);
//   } catch (e) {
//     setError('Failed to delete project');
//   }
// }

// Future<void> archiveProject(String id) async {
//   try {
//     await repository.archiveProject(id);

//     _projects.removeWhere((p) => p.id == id);

//     setLoaded(_projects);
//   } catch (e) {
//     setError(e.toString());
//   }
// }

//   void initialize() {
//     loadProjects();
//   }

//   void selectProject(ProjectModel project) {
//     // _selectedProject = project;
//     // notifyListeners();
//   }

//   void clearSearch() {
//     setLoaded(_projects);
//   }
// }

import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:fusion_web/features/projects/data/models/project_model.dart';
import 'package:fusion_web/features/projects/data/repositories/projects_repository.dart';

class ProjectsViewModel extends BaseViewModel<List<ProjectModel>> {
  final ProjectsRepository repository;

  ProjectsViewModel({required this.repository});

  List<ProjectModel> _allProjects = [];
  String _searchQuery = '';
  String _region = 'All';
  String _status = 'All';
  // List<ProjectModel> _projects = [];
  // List<ProjectModel> _filteredProjects = [];
  // ProjectModel? _selectedProject;
  // String _searchQuery = '';

  // List<ProjectModel> get projects {
  //   if (_filteredProjects.isNotEmpty) {
  //     return _filteredProjects;
  //   }
  //   return _projects;
  // }

  // ProjectModel? get selectedProject => _selectedProject;
  // String get searchQuery => _searchQuery;

  Future<void> loadProjects() async {
    try {
      setLoading();

      final projects = await repository.getProjects();

      _allProjects = projects;

      setLoaded(projects);
    } catch (e) {
      setError('Failed to load projects');
    }
  }

  Future<void> searchProjects(String query) async {
    _searchQuery = query;

    _applyFilters();
  }

  Future<void> filterProjects({String? region, String? status}) async {
    if (region != null) _region = region;
    if (status != null) _status = status;

    _applyFilters();
  }

  Future<void> getProject(String id) async {
    // try {
    //   setLoading();

    //   final project = await repository.getProjectById(id);

    //   setLoaded(project);
    // } catch (e) {
    //   setError('Failed to load project');
    // }
  }

  Future<void> deleteProject(String id) async {
    try {
      await repository.deleteProject(id);

      loadProjects();
    } catch (e) {
      setError('Failed to delete project');
    }
  }

  Future<void> archiveProject(String id) async {
    setLoading();
    try {
      await repository.archiveProject(id);
      loadProjects();
    } catch (e) {
      setError(e.toString());
    }
  }

  void initialize() {
    loadProjects();
  }

  void selectProject(ProjectModel project) {
    // _selectedProject = project;
    // notifyListeners();
  }

  void clearSearch() {
    loadProjects();
    // _searchQuery = '';
    // _filteredProjects = [];
    // notifyListeners();
  }

  void _applyFilters() {
  final filtered = _allProjects.where((p) {
    final searchMatch =
        _searchQuery.isEmpty ||
        p.name.toLowerCase().contains(_searchQuery.toLowerCase());

    final regionMatch =
        _region == 'All' || p.region == _region;

    final statusMatch =
        _status == 'All' || p.status == _status;

    return searchMatch && regionMatch && statusMatch;
  }).toList();

  setLoaded(filtered);
}
}

