part of 'project_view_model.dart';

@immutable
sealed class ProjectViewModelState {}

final class ProjectViewModelInitial extends ProjectViewModelState {}

final class ProjectLoading extends ProjectViewModelState {}

final class CreatingProject extends ProjectViewModelState {}

final class ProjectLoaded extends ProjectViewModelState {
  final List<ProjectData> projects;
  final ProjectData? currentProject;

  ProjectLoaded({required this.projects, this.currentProject});
}

final class ProjectUpdated extends ProjectViewModelState {
  final String projectId;

  ProjectUpdated({required this.projectId});
}

final class FloorsUpdated extends ProjectViewModelState {
  FloorsUpdated();
}

final class ProjectError extends ProjectViewModelState {
  final String message;

  ProjectError({required this.message});
}
