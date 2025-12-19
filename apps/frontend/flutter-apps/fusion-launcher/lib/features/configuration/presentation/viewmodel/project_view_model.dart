import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

export 'circuit/circuit_viewmodel.dart';

///Export all other view models extensions
export 'floor/floor_view_model.dart';
export 'hardware/hardware_view_model.dart';
export 'listening_area/listening_area_view_model.dart';
export 'processing_block/processing_block_viewmodel.dart';
export 'project_images/project_image_view_model.dart';
export 'project_properties/project_properties_view_model.dart';
export 'source_set/source_set_view_model.dart';
export 'subzones/subzone_view_model.dart';
export 'undo_redo/undo_redo_view_model.dart';
export 'wiring_connection/wiring_connection_view_model.dart';
export 'zone/zone_view_model.dart';
export 'functions/functions_view_model.dart';
export 'mix_scenes/mix_scenes_view_model.dart';
export 'equip_location/equip_location_view_model.dart';
export 'scenes_view_model/scenes_view_model.dart';
export 'schedule/schedule_view_model.dart';
export 'events/events_view_model.dart';

part 'project_view_model_state.dart';

enum ProjectMode {
  normal,
  listeningAreaSelection,
  zoneSelection,
  deviceSelection,
  systemListingMode,
  systemWiringMode,
}

enum ToolbarMode { acoustics, system }

enum ConfigurationMenuMode { processing, snapshots, events, gpio, scheduling }

enum SelectedItemType {
  source,
  sourceSet,
  endpoint,
  processor,
  amplifier,
  controller,
  racks,
  switchs,
  zone,
  subzone,
  circuit,
}

class SelectedItem {
  final String id;
  final SelectedItemType type;

  const SelectedItem({
    required this.id,
    required this.type,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SelectedItem && other.id == id && other.type == type;
  }

  @override
  int get hashCode => Object.hash(id, type);

  @override
  String toString() => 'DeviceSelection(id: $id, type: $type)';
}

class ProjectViewModel extends Cubit<ProjectViewModelState> {
  final ProjectManager projectManager;

  ProjectViewModel(this.projectManager) : super(ProjectViewModelInitial());

  List<ProjectData> allProjects = <ProjectData>[];

  ProjectData? _currentProject;

  int get totalProjects => allProjects.length;

  bool get hasProjects => allProjects.isNotEmpty;

  /// Temp variables for various selections
  String? currentSelectedHardwareId;
  String? currentSelectedListeningAreaId;
  String? currentSelectedZoneId;
  String? currentSelectedSubZoneId;

  /// Listening area selection mode flag
  bool isInListeningAreaMode = false;
  bool isInZoneSelectionMode = false;

  int currentDeviceTypeIndex = -1;

  ProjectMode currentProjectMode = ProjectMode.systemListingMode;

  ToolbarMode currentToolbarMode = ToolbarMode.acoustics;
  ConfigurationMenuMode currentConfigurationMenuMode = ConfigurationMenuMode.processing;

  ProductQueryModel? selectedProductToAdd;

  /// Global hover and selection state management
  SelectedItem? _selectedDevice;

  SelectedItem? get selectedDevice => _selectedDevice;

  /// Update selection state
  void setSelectedDevice(String? deviceId, SelectedItemType? type) {
    final SelectedItem? newSelectedDevice = (deviceId != null && type != null) ? SelectedItem(id: deviceId, type: type) : null;

    if (_selectedDevice != newSelectedDevice) {
      _selectedDevice = newSelectedDevice;
      emit(DeviceSelectionChanged(_selectedDevice));
    }
  }

  /// Clear all selections
  void clearSelections() {
    bool changed = false;

    if (_selectedDevice != null) {
      _selectedDevice = null;
      changed = true;
    }
    if (changed) {
      emit(DeviceSelectionsCleared());
    }
  }

  /// Loads all local projects and emits the appropriate state.
  Future<void> loadAllLocalProjects() async {
    print("Loading all local projects...");
    emit(ProjectLoading());
    try {
      final ResponseCallback<List<ProjectData>> projectsResponse = await projectManager.loadProjectsFromLocal();
      if (projectsResponse.success) {
        allProjects = projectsResponse.data ?? <ProjectData>[];
        emit(
          ProjectLoaded(
            projects: projectsResponse.data ?? <ProjectData>[],
            currentProject: null,
          ),
        );
      } else {
        emit(
          ProjectError(
            message: "Failed to load projects: ${projectsResponse.message}",
          ),
        );
        return;
      }
    } catch (e) {
      emit(ProjectError(message: "Failed to load project: $e"));
    }
  }

  /// Save Project to local storage
  Future<void> saveProject() async {
    emit(ProjectLoading());
    try {
      print("Saving current project...");
      final ResponseCallback<void> saveResponse = await projectManager.saveCurrentProject();
      if (!saveResponse.success) {
        emit(
          ProjectError(
            message: "Failed to save project: ${saveResponse.message}",
          ),
        );
        return;
      }
    } catch (e) {
      emit(ProjectError(message: "Failed to save project: $e"));
    }
  }

  /// Delete Project from local storage
  Future<void> deleteProjectFromLocal(String projectId) async {
    try {
      final ResponseCallback<void> deleteResponse = await projectManager.deleteProject(projectId);
      if (deleteResponse.success) {
        // Reload projects after deletion
        await loadAllLocalProjects();
      } else {
        emit(
          ProjectError(
            message: "Failed to delete project: ${deleteResponse.message}",
          ),
        );
        return;
      }
    } catch (e) {
      FusionLogger.log(tag: LogTag.exceptions, message: "Failed to delete project: $e");
      emit(ProjectError(message: "Failed to delete project: $e"));
    }
  }

  /// Delete Current Project from local storage
  Future<void> deleteCurrentProjectFromLocal() async {
    if (_currentProject == null) {
      emit(ProjectError(message: "No project is currently open."));
      return;
    }
    await deleteProjectFromLocal(_currentProject!.id);
    _currentProject = null;
  }

  /// Create new Project and save to local storage
  Future<ProjectData?> createAndSaveNewProject(
    NewProjectDetails newProject,
  ) async {
    emit(CreatingProject());
    try {
      final ResponseCallback<ProjectData?> saveResponse = await projectManager.createAndSaveNewProject(newProject);
      if (saveResponse.success) {
        // Reload projects after creation
        await loadAllLocalProjects();
        return saveResponse.data;
      } else {
        emit(
          ProjectError(
            message: "Failed to create project: ${saveResponse.message}",
          ),
        );
        return null;
      }
    } catch (e) {
      emit(ProjectError(message: "Failed to create project: $e"));
    }
    return null;
  }

  ///Open project by Project id
  void openProject(String projectId) {
    final ResponseCallback<ProjectData> projectResponse = projectManager.openProjectById(projectId);

    if (projectResponse.success && projectResponse.data != null) {
      _currentProject = projectResponse.data;
      emit(
        ProjectLoaded(
          projects: allProjects,
          currentProject: projectResponse.data,
        ),
      );
    } else {
      emit(
        OpenProjectError(
          message: "Unable to open project: ${projectResponse.message}",
        ),
      );
      // throwError("Unable to open project ${projectResponse.message}");
    }
  }

  /// get Project json
  Map<String, dynamic> getProjectJson() {
    return projectManager.getCurrentProjectJson();
  }

  /// Clears the current project selection.
  void closeProject() {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;
      _currentProject = null;
      emit(
        ProjectLoaded(projects: currentState.projects, currentProject: null),
      );
    }
  }

  void updateProject() {
    if (_currentProject != null) {
      emit(ProjectUpdated(projectId: _currentProject!.id));
    }
  }

  void emitFloorUpdated() {
    emit(FloorsUpdated());
  }

  void throwError(String message) {
    emit(ProjectError(message: message));
  }

  void exitSelectionModes() {
    isInListeningAreaMode = false;
    isInZoneSelectionMode = false;
    currentSelectedListeningAreaId = null;
    currentSelectedZoneId = null;
    currentSelectedSubZoneId = null;
    updateProject();
  }

  void enterZoneSelectionMode(Zone zone) {
    isInListeningAreaMode = false;
    isInZoneSelectionMode = true;
    currentSelectedZoneId = zone.id;
    currentSelectedListeningAreaId = null;
    currentSelectedSubZoneId = null;
    resetDeviceTypeIndex();
    emit(ZoneSelectionMode(zone));
  }

  void enterSubZoneSelectionMode(SubZone subZone) {
    isInListeningAreaMode = false;
    isInZoneSelectionMode = true;
    currentSelectedSubZoneId = subZone.id;
    currentSelectedZoneId = null;
    currentSelectedListeningAreaId = null;
    resetDeviceTypeIndex();
    emit(SubZoneSelectionMode(subZone));
  }

  void enterListeningAreaMode() {
    isInZoneSelectionMode = false;
    isInListeningAreaMode = true;
    currentSelectedZoneId = null;
    currentSelectedSubZoneId = null;
    resetDeviceTypeIndex();
    emit(ListeningAreaSelectionMode());
  }

  Color getCurrentSelectionZoneColor() {
    if (currentSelectedZoneId != null) {
      final Zone zone = projectManager.getZoneById(currentSelectedZoneId!);
      return zone.color;
    } else if (currentSelectedSubZoneId != null) {
      final Zone zone = projectManager.getZoneForSubZone(
        subZoneId: currentSelectedSubZoneId!,
      );
      return zone.color;
    }
    return Colors.grey;
  }

  String getCurrentSelectionZoneName() {
    if (currentSelectedZoneId != null) {
      final Zone zone = projectManager.getZoneById(currentSelectedZoneId!);
      return zone.name;
    } else if (currentSelectedSubZoneId != null) {
      final Zone zone = projectManager.getZoneForSubZone(
        subZoneId: currentSelectedSubZoneId!,
      );
      return zone.name;
    }
    return "Unknown Zone";
  }

  void changeDeviceTypeIndex(int index) {
    currentDeviceTypeIndex = index;
    isInZoneSelectionMode = false;
    isInListeningAreaMode = false;
    currentSelectedZoneId = null;
    currentSelectedSubZoneId = null;
    print("Device type index changed to $index");
    emit(DeviceTypeIndexChanged(index));
  }

  void resetDeviceTypeIndex() {
    currentDeviceTypeIndex = -1;
  }

  void setToolbarMode(ToolbarMode mode) {
    if (currentToolbarMode != mode) {
      currentToolbarMode = mode;
      // Reset selections when switching modes
      changeDeviceTypeIndex(-1);
      setSelectedProductToAdd(null);
      emit(ToolbarModeChanged(mode));
    }
  }

  void setConfigurationMenuMode(ConfigurationMenuMode mode) {
    if (currentConfigurationMenuMode != mode) {
      currentConfigurationMenuMode = mode;
      emit(ConfigurationMenuModeChanged(mode));
    }
  }

  void setSelectedProductToAdd(ProductQueryModel? product) {
    selectedProductToAdd = product;
    emit(ProductToAddChanged(product));
  }

  void setProjectMode(ProjectMode mode) {
    currentProjectMode = mode;
    updateProject();
  }

  void resetProjectMode() {
    currentProjectMode = ProjectMode.normal;
    updateProject();
  }

  void deleteSelectedItem() {
    if (_selectedDevice != null) {
      switch (_selectedDevice!.type) {
        case SelectedItemType.source:
        case SelectedItemType.endpoint:
        case SelectedItemType.processor:
        case SelectedItemType.controller:
        case SelectedItemType.amplifier:
        case SelectedItemType.racks:
        case SelectedItemType.switchs:
        case SelectedItemType.circuit:
          projectManager.removeHardware(_selectedDevice!.id);
          break;
        case SelectedItemType.zone:
          projectManager.removeZone(_selectedDevice!.id);
          break;
        case SelectedItemType.subzone:
          projectManager.removeSubZone(_selectedDevice!.id);
          break;
        case SelectedItemType.sourceSet:
          projectManager.removeSourceSet(_selectedDevice!.id);
          break;
      }
      clearSelections();
      updateProject();
    }
  }

  Future<File?> getCurrentProjectFile() async {
    if (_currentProject != null) {
      return projectManager.getProjectZipFile(projectId: _currentProject!.id);
    } else {
      FusionLogger.log(tag: LogTag.exceptions, message: "No project is currently open.");
      return null;
    }
  }

  /// Selected snapshot ID for actions panel
  String? selectedSnapshotId;

  void setSelectedSnapshotId(String? snapshotId) {
    selectedSnapshotId = snapshotId;
    emit(ProjectUpdated(projectId: _currentProject?.id ?? ''));
  }

  /// Selected event ID for actions panel
  String? selectedEventId;

  void setSelectedEventId(String? eventId) {
    selectedEventId = eventId;
    emit(ProjectUpdated(projectId: _currentProject?.id ?? ''));
  }
}
