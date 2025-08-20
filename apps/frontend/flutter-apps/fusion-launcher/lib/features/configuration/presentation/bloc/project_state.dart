part of 'project_bloc.dart';

abstract class ProjectState extends Equatable {
  const ProjectState();

  @override
  List<Object?> get props => <Object?>[];
}

class ProjectInitial extends ProjectState {}

class ProjectLoading extends ProjectState {}

class ProjectLoaded extends ProjectState {
  final ProjectEntity project;
  final String? selectedFloorPlanId;
  final String? selectedListeningAreaId;
  final String? selectedHardwareComponentId;

  const ProjectLoaded({
    required this.project,
    this.selectedFloorPlanId,
    this.selectedListeningAreaId,
    this.selectedHardwareComponentId,
  });

  ProjectLoaded copyWith({
    ProjectEntity? project,
    String? selectedFloorPlanId,
    String? selectedListeningAreaId,
    String? selectedHardwareComponentId,
    bool clearFloorPlan = false,
    bool clearListeningArea = false,
    bool clearHardwareComponent = false,
  }) {
    return ProjectLoaded(
      project: project ?? this.project,
      selectedFloorPlanId: clearFloorPlan ? null : (selectedFloorPlanId ?? this.selectedFloorPlanId),
      selectedListeningAreaId: clearListeningArea ? null : (selectedListeningAreaId ?? this.selectedListeningAreaId),
      selectedHardwareComponentId: clearHardwareComponent ? null : (selectedHardwareComponentId ?? this.selectedHardwareComponentId),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    project,
    selectedFloorPlanId,
    selectedListeningAreaId,
    selectedHardwareComponentId,
  ];
}

class ProjectError extends ProjectState {
  final String message;

  const ProjectError(this.message);

  @override
  List<Object> get props => <Object>[message];
}
