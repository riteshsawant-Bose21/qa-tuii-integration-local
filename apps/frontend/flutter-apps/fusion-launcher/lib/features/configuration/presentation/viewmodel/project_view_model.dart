import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:fusion_lib/fusion_lib.dart';

///Export all other view models extensions
export 'floor/floor_view_model.dart';
export 'hardware/hardware_view_model.dart';
export 'listening_area/listening_area_view_model.dart';
export 'source_set/source_set_view_model.dart';
export 'zone/zone_view_model.dart';
export 'project_properties/project_properties_view_model.dart';
export 'undo_redo/undo_redo_view_model.dart';
export 'project_images/project_image_view_model.dart';

part 'project_view_model_state.dart';

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

  /// Listening area selection mode flag
  bool isInListeningAreaSelectionMode = false;
  bool isInZoneSelectionMode = false;

  int currentDeviceTypeIndex = -1;

  ProductQueryModel? selectedProductToAdd;

  /// Loads all local projects and emits the appropriate state.
  Future<void> loadAllLocalProjects() async {
    emit(ProjectLoading());
    try {
      final ResponseCallback<List<ProjectData>> projectsResponse = await projectManager.loadProjectsFromLocal();
      if (projectsResponse.success) {
        allProjects = projectsResponse.data ?? <ProjectData>[];
        emit(ProjectLoaded(projects: projectsResponse.data ?? <ProjectData>[], currentProject: null));
      } else {
        emit(ProjectError(message: "Failed to load projects: ${projectsResponse.message}"));
        return;
      }
    } catch (e) {
      emit(ProjectError(message: "Failed to load project: $e"));
    }
  }

  /// Save Project to local storage
  Future<void> saveProjectToLocal() async {
    emit(ProjectLoading());
    try {
      final ResponseCallback<void> saveResponse = await projectManager.saveCurrentProject();
      if (saveResponse.success) {
        // Reload projects after saving
        await loadAllLocalProjects();
      } else {
        emit(ProjectError(message: "Failed to save project: ${saveResponse.message}"));
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
        emit(ProjectError(message: "Failed to delete project: ${deleteResponse.message}"));
        return;
      }
    } catch (e) {
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
  Future<ProjectData?> createAndSaveNewProject(NewProjectDetails newProject) async {
    emit(CreatingProject());
    try {
      final ResponseCallback<ProjectData?> saveResponse = await projectManager.createAndSaveNewProject(newProject);
      if (saveResponse.success) {
        // Reload projects after creation
        await loadAllLocalProjects();
        return saveResponse.data;
      } else {
        emit(ProjectError(message: "Failed to create project: ${saveResponse.message}"));
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
      emit(ProjectLoaded(projects: allProjects, currentProject: projectResponse.data));
    } else {
      throwError("Unable to open project ${projectResponse.message}");
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
      emit(ProjectLoaded(projects: currentState.projects, currentProject: null));
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

  void enterZoneSelectionMode(Zone zone) {
    isInListeningAreaSelectionMode = false;
    isInZoneSelectionMode = true;
    currentSelectedZoneId = zone.id;
    resetDeviceTypeIndex();
    emit(ZoneSelectionMode(zone));
  }

  void enterListeningAreaSelectionMode() {
    isInZoneSelectionMode = false;
    isInListeningAreaSelectionMode = true;
    currentSelectedZoneId = null;
    resetDeviceTypeIndex();
    emit(ListeningAreaSelectionMode());
  }

  void changeDeviceTypeIndex(int index) {
    currentDeviceTypeIndex = index;
    isInZoneSelectionMode = false;
    isInListeningAreaSelectionMode = false;
    currentSelectedZoneId = null;
    print("Device type index changed to $index");
    emit(DeviceTypeIndexChanged(index));
  }

  void resetDeviceTypeIndex() {
    currentDeviceTypeIndex = -1;
  }
}
