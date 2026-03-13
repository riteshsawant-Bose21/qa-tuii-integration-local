import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';

class BuildingPageState {
  final ToolbarMode toolbarMode;
  final BuildingPageToolState toolState;

  BuildingPageState({required this.toolbarMode, required this.toolState});

  @override
  bool operator ==(covariant BuildingPageState other) {
    if (identical(this, other)) return true;

    return other.toolbarMode == toolbarMode && other.toolState == toolState;
  }

  @override
  int get hashCode => toolbarMode.hashCode ^ toolState.hashCode;

  static BuildingPageState defaultAcousticsState() {
    return BuildingPageState(toolbarMode: ToolbarMode.acoustics, toolState: DrawingListingAreaState());
  }

  static BuildingPageState defaultSystemState() {
    return BuildingPageState(toolbarMode: ToolbarMode.system, toolState: SystemToolState());
  }
}

enum SplState {
  live,
  display,
  hidden,
}

abstract class BuildingPageToolState {}

class SystemToolState extends BuildingPageToolState {}

class DrawingListingAreaState extends BuildingPageToolState {}

class MeasuringToolState extends BuildingPageToolState {}

class SelectToolState extends BuildingPageToolState {}
