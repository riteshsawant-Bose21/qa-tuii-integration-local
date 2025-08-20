part of 'project_bloc.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => <Object?>[];
}

// Project Events
class LoadProject extends ProjectEvent {
  final String projectName;

  const LoadProject(this.projectName);

  @override
  List<Object> get props => <Object>[projectName];
}

class SaveProject extends ProjectEvent {}

class DeleteProject extends ProjectEvent {}

class UpdateProjectName extends ProjectEvent {
  final String newName;

  const UpdateProjectName(this.newName);

  @override
  List<Object> get props => <Object>[newName];
}

class SetCloudId extends ProjectEvent {
  final String cloudId;

  const SetCloudId(this.cloudId);

  @override
  List<Object> get props => <Object>[cloudId];
}

// Selection Events
class SetSelectedFloorPlan extends ProjectEvent {
  final String? floorPlanId;

  const SetSelectedFloorPlan(this.floorPlanId);

  @override
  List<Object?> get props => <Object?>[floorPlanId];
}

class SetSelectedListeningArea extends ProjectEvent {
  final String? listeningAreaId;

  const SetSelectedListeningArea(this.listeningAreaId);

  @override
  List<Object?> get props => <Object?>[listeningAreaId];
}

class SetSelectedHardwareComponent extends ProjectEvent {
  final String? hardwareComponentId;

  const SetSelectedHardwareComponent(this.hardwareComponentId);

  @override
  List<Object?> get props => <Object?>[hardwareComponentId];
}

class ClearAllSelections extends ProjectEvent {}

// Floor Events
class AddFloor extends ProjectEvent {
  final Floor floor;

  const AddFloor(this.floor);

  @override
  List<Object> get props => <Object>[floor];
}

class UpdateFloor extends ProjectEvent {
  final Floor floor;

  const UpdateFloor(this.floor);

  @override
  List<Object> get props => <Object>[floor];
}

class RemoveFloor extends ProjectEvent {
  final String floorId;

  const RemoveFloor(this.floorId);

  @override
  List<Object> get props => <Object>[floorId];
}

class SetCurrentFloor extends ProjectEvent {
  final int index;

  const SetCurrentFloor(this.index);

  @override
  List<Object> get props => <Object>[index];
}

// Hardware Component Events
class AddHardwareComponent extends ProjectEvent {
  final HardwareComponent component;

  const AddHardwareComponent(this.component);

  @override
  List<Object> get props => <Object>[component];
}

class UpdateHardwareComponent extends ProjectEvent {
  final HardwareComponent component;

  const UpdateHardwareComponent(this.component);

  @override
  List<Object> get props => <Object>[component];
}

class RemoveHardwareComponent extends ProjectEvent {
  final String componentId;

  const RemoveHardwareComponent(this.componentId);

  @override
  List<Object> get props => <Object>[componentId];
}

// Listening Area Events
class AddListeningArea extends ProjectEvent {
  final ListeningArea listeningArea;

  const AddListeningArea(this.listeningArea);

  @override
  List<Object> get props => <Object>[listeningArea];
}

class UpdateListeningArea extends ProjectEvent {
  final ListeningArea listeningArea;

  const UpdateListeningArea(this.listeningArea);

  @override
  List<Object> get props => <Object>[listeningArea];
}

class RemoveListeningArea extends ProjectEvent {
  final String listeningAreaId;

  const RemoveListeningArea(this.listeningAreaId);

  @override
  List<Object> get props => <Object>[listeningAreaId];
}

// Mix Events
class AddMix extends ProjectEvent {
  final Mix mix;

  const AddMix(this.mix);

  @override
  List<Object> get props => <Object>[mix];
}

class UpdateMix extends ProjectEvent {
  final Mix mix;

  const UpdateMix(this.mix);

  @override
  List<Object> get props => <Object>[mix];
}

class RemoveMix extends ProjectEvent {
  final String mixId;

  const RemoveMix(this.mixId);

  @override
  List<Object> get props => <Object>[mixId];
}

// Zone Events
class AddZone extends ProjectEvent {
  final Zone zone;

  const AddZone(this.zone);

  @override
  List<Object> get props => <Object>[zone];
}

class UpdateZone extends ProjectEvent {
  final Zone zone;

  const UpdateZone(this.zone);

  @override
  List<Object> get props => <Object>[zone];
}

class RemoveZone extends ProjectEvent {
  final String zoneId;

  const RemoveZone(this.zoneId);

  @override
  List<Object> get props => <Object>[zoneId];
}

// Cloud Events
class UploadToCloud extends ProjectEvent {}

class DownloadFromCloud extends ProjectEvent {
  final String fileId;

  const DownloadFromCloud(this.fileId);

  @override
  List<Object> get props => <Object>[fileId];
}
