import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:fusion_lib/fusion_lib.dart';

part 'project_view_model_state.dart';

class ProjectViewModel extends Cubit<ProjectViewModelState> {
  final ProjectManager projectManager;

  ProjectViewModel(this.projectManager) : super(ProjectViewModelInitial());

  List<ProjectData> allProjects = <ProjectData>[];

  ProjectData? _currentProject;

  int get totalProjects => allProjects.length;

  bool get hasProjects => allProjects.isNotEmpty;

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

  /// Sets the current project and emits the appropriate state.
  void setCurrentProject(ProjectData project) async {
    if (state is ProjectLoaded) {
      final ProjectLoaded currentState = state as ProjectLoaded;
      _currentProject = project;
      emit(ProjectLoaded(projects: currentState.projects, currentProject: project));
    }
  }

  /// Clears the current project selection.
  void clearCurrentProject() {
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

  void throwError(String message) {
    emit(ProjectError(message: message));
  }
}
