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

final class OpenProjectError extends ProjectViewModelState {
  final String message;

  OpenProjectError({required this.message});
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

final class ZoneSelectionMode extends ProjectViewModelState {
  final Zone zone;
  ZoneSelectionMode(this.zone);
}

final class SubZoneSelectionMode extends ProjectViewModelState {
  final SubZone subZone;
  SubZoneSelectionMode(this.subZone);
}

final class ListeningAreaSelectionMode extends ProjectViewModelState {
  ListeningAreaSelectionMode();
}

final class DeviceTypeIndexChanged extends ProjectViewModelState {
  final int index;
  DeviceTypeIndexChanged(this.index);
}

final class DeviceHoverChanged extends ProjectViewModelState {
  final SelectedItem? hoveredDevice;
  DeviceHoverChanged(this.hoveredDevice);
}

final class DeviceSelectionChanged extends ProjectViewModelState {
  final SelectedItem? selectedDevice;
  DeviceSelectionChanged(this.selectedDevice);
}

final class DeviceSelectionsCleared extends ProjectViewModelState {}

final class ToolbarModeChanged extends ProjectViewModelState {
  final ToolbarMode mode;
  ToolbarModeChanged(this.mode);
}

final class ConfigurationMenuModeChanged extends ProjectViewModelState {
  final ConfigurationMenuMode mode;
  ConfigurationMenuModeChanged(this.mode);
}

final class ProductToAddChanged extends ProjectViewModelState {
  final ProductQueryModel? product;
  ProductToAddChanged(this.product);
}
