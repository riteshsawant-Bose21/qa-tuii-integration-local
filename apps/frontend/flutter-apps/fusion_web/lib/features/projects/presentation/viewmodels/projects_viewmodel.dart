import 'dart:async';
import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:fusion_web/core/presentation/search_delegate_mixin.dart';
import 'package:fusion_web/features/projects/data/models/project_model.dart';
import 'package:fusion_web/features/projects/data/repositories/projects_repository.dart';

class ProjectsViewModel extends BaseViewModel<List<ProjectModel>>
    with SearchDelegateMixin<ProjectModel> {
  final ProjectsRepository repository;
  Timer? _debounce;

  ProjectsViewModel({required this.repository});

  // ================= STATE =================
  String _searchQuery = '';
  String region = 'All';
  String status = 'All';
  bool isGridView = false;

  // ================= MAIN METHOD =================
  Future<void> applyFilters({bool showLoader = true}) async {
    try {
      if (showLoader) setLoading();

      final projects = await repository.getProjectsFiltered(
        search: _searchQuery,
        region: region == 'All' ? null : region,
        status: status == 'All' ? null : status,
      );

      setLoaded(projects);
    } catch (e) {
      setError('Failed to load projects');
    }
  }

  // ================= UPDATE METHODS =================

  void updateSearch(String value) {
    _searchQuery = value;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      applyFilters(showLoader: false);
    });
  }

  void updateRegion(String value) {
    region = value;
    applyFilters();
  }

  void updateStatus(String value) {
    status = value;
    applyFilters();
  }

  void clearFilters() {
    _searchQuery = '';
    region = 'All';
    status = 'All';

    applyFilters();
  }

  // ================= ACTIONS =================

  Future<void> deleteProject(String id) async {
    try {
      await repository.deleteProject(id);
      await applyFilters(showLoader: false);
    } catch (e) {
      setError('Failed to delete project');
    }
  }

  Future<void> archiveProject(String id) async {
    try {
      setLoading();
      await repository.archiveProject(id);
      await applyFilters(showLoader: false);
    } catch (e) {
      setError(e.toString());
    }
  }

  // ================= VIEW TOGGLE =================

  void toggleView(bool isGrid) {
    isGridView = isGrid;

    if (state is LoadedState<List<ProjectModel>>) {
      setLoaded((state as LoadedState<List<ProjectModel>>).data);
    }
  }

  // ================= INIT =================

  void initialize() {
    applyFilters();
  }

  // ================= SEARCH DELEGATE =================

  @override
  Future<List<ProjectModel>> search(String? query) async {
    _searchQuery = query ?? '';
    await applyFilters(showLoader: false);

    return (state as LoadedState<List<ProjectModel>>).data;
  }

  // ================= OPTIONAL =================

  bool get hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        region != 'All' ||
        status != 'All';
  }
}