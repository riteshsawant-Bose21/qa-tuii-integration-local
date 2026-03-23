import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:fusion_web/features/devices/data/models/devices_model.dart';
import 'package:fusion_web/features/devices/data/repositories/devices_repository.dart';

class DevicesViewModel extends BaseViewModel<DevicesModel> {
  final DevicesRepository repository;

  DevicesViewModel(this.repository);

  // FILTER STATE
  String searchQuery = '';
  String selectedProject = 'All Projects';
  String selectedStatus = 'All Status';
  String selectedModel = 'All Models';
  String selectedType = 'All Types';
  String selectedCategory = 'Name';
  String? selectedProjectId;

  bool isGridView = false;

  bool get hasActiveFilters {
    return searchQuery.isNotEmpty ||
        selectedProject != 'All Projects' ||
        selectedStatus != 'All Status' ||
        selectedModel != 'All Models' ||
        selectedType != 'All Types' ||
        selectedCategory != 'Name';
  }

  /// LOAD INITIAL DATA
  Future<void> loadDevices() async {
    await applyFilters();
  }

  /// MAIN METHOD 
  Future<void> applyFilters() async {
    setLoading();

    try {
      final result = await repository.getFilteredDevices(
        searchQuery: searchQuery,
        status: selectedStatus,
        project: selectedProject,
        model: selectedModel,
        type: selectedType,
        category: selectedCategory,
        projectId: selectedProjectId,
      );

      setLoaded(result);
    } catch (e) {
      setError(e.toString());
    }
  }

  /// UPDATE METHODS

  void updateSearch(String value) {
    searchQuery = value;
    applyFilters();
  }

  void updateStatus(String value) {
    selectedStatus = value;
    applyFilters();
  }

  void updateProject(String value) {
    selectedProject = value;
    applyFilters();
  }

  void updateModel(String value) {
    selectedModel = value;
    applyFilters();
  }

  void updateType(String value) {
    selectedType = value;
    applyFilters();
  }

  void updateCategory(String value) {
    selectedCategory = value;
    applyFilters();
  }

  void clearFilters() {
    searchQuery = '';
    selectedProject = 'All Projects';
    selectedStatus = 'All Status';
    selectedModel = 'All Models';
    selectedType = 'All Types';
    selectedCategory = 'Name';

    applyFilters();
  }

  void toggleGrid(bool grid) {
    isGridView = grid;

    if (state is LoadedState<DevicesModel>) {
      setLoaded((state as LoadedState<DevicesModel>).data);
    }
  }
}

