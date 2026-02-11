part of 'project_sync_view_model.dart';

/// Base state for project upload
abstract class ProjectSyncViewModelState extends Equatable {
  const ProjectSyncViewModelState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state
class ProjectUploadInitial extends ProjectSyncViewModelState {}

class LoadingAllProjects extends ProjectSyncViewModelState {}

class AllProjectsLoaded extends ProjectSyncViewModelState {
  final List<ProjectData> projects;

  const AllProjectsLoaded({required this.projects});

  @override
  List<Object?> get props => <Object?>[projects];
}

class ProjectsLoadFailure extends ProjectSyncViewModelState {
  final String error;

  const ProjectsLoadFailure({required this.error});

  @override
  List<Object?> get props => <Object?>[error];
}

/// Upload in progress
class ProjectUploadInProgress extends ProjectSyncViewModelState {
  final String projectId;
  final double progress;

  const ProjectUploadInProgress({
    required this.projectId,
    required this.progress,
  });

  @override
  List<Object?> get props => <Object?>[projectId, progress];
}

/// Upload successful
class ProjectUploadSuccess extends ProjectSyncViewModelState {
  final String projectId;

  const ProjectUploadSuccess({required this.projectId});

  @override
  List<Object?> get props => <Object?>[projectId];
}

/// Upload failed
class ProjectUploadFailure extends ProjectSyncViewModelState {
  final String error;

  const ProjectUploadFailure({required this.error});

  @override
  List<Object?> get props => <Object?>[error];
}

/// Upload cancelled
class ProjectUploadCancelled extends ProjectSyncViewModelState {}

class ProjectDownloadInProgress extends ProjectSyncViewModelState {
  final String projectId;
  final double progress;
  final String downloadPhase;

  const ProjectDownloadInProgress({
    required this.projectId,
    required this.progress,
    this.downloadPhase = 'Downloading',
  });

  @override
  List<Object?> get props => <Object?>[projectId, progress, downloadPhase];
}

class ProjectDownloadSuccess extends ProjectSyncViewModelState {
  final String projectId;

  const ProjectDownloadSuccess({required this.projectId});

  @override
  List<Object?> get props => <Object?>[projectId];
}

class ProjectDownloadFailure extends ProjectSyncViewModelState {
  final String error;

  const ProjectDownloadFailure({required this.error});

  @override
  List<Object?> get props => <Object?>[error];
}
