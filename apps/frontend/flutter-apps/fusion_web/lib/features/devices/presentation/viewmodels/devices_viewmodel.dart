import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:fusion_web/features/devices/data/models/devices_model.dart';
import 'package:fusion_web/features/devices/data/repositories/devices_repository.dart';

class DevicesViewModel extends BaseViewModel<DevicesModel> {
  final DevicesRepository repository;

  DevicesViewModel(this.repository);

  DevicesModel? _originalData;

  //project based filter
  String? selectedProjectId;

  /// FILTER STATE
  String searchQuery = '';
  String selectedProject = 'All Projects';
  String selectedStatus = 'All Status';
  String selectedModel = 'All Models';
  String selectedType = 'All Types';
  String selectedCategory = 'Name';

  bool isGridView = false;

  bool get hasActiveFilters {
    return searchQuery.isNotEmpty ||
        selectedProject != 'All Projects' ||
        selectedStatus != 'All Status' ||
        selectedModel != 'All Models' ||
        selectedType != 'All Types' ||
        selectedCategory != 'Name';
  }

  /// =============================
  /// LOAD DEVICES
  /// =============================

  Future<void> loadDevices() async {
    setLoading();

    try {
      final result = await repository.getDeviceStats();
      _originalData = result;
      _applyFilters();
    } catch (e) {
      setError(e.toString());
    }
  }

  /// =============================
  /// UPDATE SEARCH
  /// =============================

  void updateSearch(String value) {
    searchQuery = value;
    _applyFilters();
  }

  /// =============================
  /// UPDATE STATUS
  /// =============================

  void updateStatus(String value) {
    selectedStatus = value;
    _applyFilters();
  }

  /// =============================
  /// UPDATE PROJECT
  /// =============================

  void updateProject(String value) {
    selectedProject = value;
    _applyFilters();
  }

  /// =============================
  /// UPDATE MODEL
  /// =============================

  void updateModel(String value) {
    selectedModel = value;
    _applyFilters();
  }

  /// =============================
  /// UPDATE TYPE
  /// =============================

  void updateType(String value) {
    selectedType = value;
    _applyFilters();
  }

  /// =============================
  /// UPDATE CATEGORY (SORT)
  /// =============================

  void updateCategory(String value) {
    selectedCategory = value;
    _applyFilters();
  }

  /// =============================
  /// CLEAR FILTERS
  /// =============================

  void clearFilters() {
    searchQuery = '';
    selectedProject = 'All Projects';
    selectedStatus = 'All Status';
    selectedModel = 'All Models';
    selectedType = 'All Types';
    selectedCategory = 'Name';

    if (_originalData != null) {
      _applyFilters();
    }
  }

  /// =============================
  /// GRID / LIST TOGGLE
  /// =============================

  void toggleGrid(bool grid) {
    isGridView = grid;

    if (state is LoadedState<DevicesModel>) {
      setLoaded((state as LoadedState<DevicesModel>).data);
    }
  }

  /// =============================
  /// APPLY FILTERS + SORT
  /// =============================

  void _applyFilters() {
    if (_originalData == null) return;

    List<Device> devices = List.from(_originalData!.devices);
print("Selected Project ID: $selectedProjectId");

for (var d in _originalData!.devices) {
  print("Device projectId: ${d.projectId}");
}
    //project id filter for project details page
    if (selectedProjectId != null) {
      devices = devices.where((d) => d.projectId == selectedProjectId).toList();
    }

    /// SEARCH
    if (searchQuery.isNotEmpty) {
      devices = devices.where((device) {
        final query = searchQuery.toLowerCase();

        return device.name.toLowerCase().contains(query) ||
            device.model.toLowerCase().contains(query);
        // device.project.toLowerCase().contains(query);
        // device.deviceId.toLowerCase().contains(query);
      }).toList();
    }

    /// STATUS
    if (selectedStatus != 'All Status') {
      devices = devices.where((device) {
        return device.status.toLowerCase() == selectedStatus.toLowerCase();
      }).toList();
    }

    /// PROJECT
    if (selectedProject != 'All Projects') {
      devices = devices.where((device) {
        return device.project == selectedProject;
      }).toList();
    }

    /// MODEL
    if (selectedModel != 'All Models') {
      devices = devices.where((device) {
        return device.model == selectedModel;
      }).toList();
    }

    /// TYPE
    if (selectedType != 'All Types') {
      devices = devices.where((device) {
        return device.type == selectedType;
      }).toList();
    }

    /// SORTING
    switch (selectedCategory) {
      case 'Name':
        devices.sort((a, b) => a.name.compareTo(b.name));
        break;

      case 'Model':
        devices.sort((a, b) => a.model.compareTo(b.model));
        break;

      case 'Status':
        const order = {'healthy': 1, 'critical': 2, 'inactive': 3};

        devices.sort((a, b) {
          final aValue = order[a.status.toLowerCase()] ?? 99;
          final bValue = order[b.status.toLowerCase()] ?? 99;
          return aValue.compareTo(bValue);
        });
        break;

      case 'Last Seen':
        devices.sort((a, b) {
          final aTime = DateTime.tryParse(a.lastSeen) ?? DateTime(1970);
          final bTime = DateTime.tryParse(b.lastSeen) ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });
        break;
    }

    final filteredModel = _originalData!.copyWith(
      devices: devices,
      total: devices.length,
      healthy: devices.where((d) => d.status == 'healthy').length,
      critical: devices.where((d) => d.status == 'critical').length,
      inactive: devices.where((d) => d.status == 'inactive').length,
    );
    setLoaded(filteredModel);
  }
}
