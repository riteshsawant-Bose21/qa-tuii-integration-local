import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';

class BuildingPageState {
  final ToolbarMode toolbarMode;
  final BuildingPageToolState toolState;

  BuildingPageState({
    required this.toolbarMode,
    required this.toolState,
  });

  String? get selectedListeningAreaId {
    if (toolState case SelectToolState(:final String? selectedListeningAreaId)) {
      return selectedListeningAreaId;
    }
    if (toolState case SpeakerPlacementState(:final String? selectedListeningAreaId)) {
      return selectedListeningAreaId;
    }
    return null;
  }

  String? get selectedSpeakerId {
    if (toolState case SelectToolState(:final String? selectedSpeakerId)) {
      return selectedSpeakerId;
    }
    if (toolState case SpeakerPlacementState(:final String? selectedSpeakerId)) {
      return selectedSpeakerId;
    }
    return null;
  }

  BuildingPageState copyWith({
    ToolbarMode? toolbarMode,
    BuildingPageToolState? toolState,
    String? selectedListeningAreaId,
    String? selectedSpeakerId,
    bool clearSelectedListeningAreaId = false,
    bool clearSelectedSpeakerId = false,
  }) {
    final String? nextListeningAreaId = clearSelectedListeningAreaId ? null : selectedListeningAreaId ?? this.selectedListeningAreaId;
    final String? nextSpeakerId = clearSelectedSpeakerId ? null : selectedSpeakerId ?? this.selectedSpeakerId;

    final BuildingPageToolState nextToolState = _copyToolStateWithSelection(
      toolState ?? this.toolState,
      selectedListeningAreaId: nextListeningAreaId,
      selectedSpeakerId: nextSpeakerId,
      clearSelectedListeningAreaId: clearSelectedListeningAreaId,
      clearSelectedSpeakerId: clearSelectedSpeakerId,
    );

    return BuildingPageState(
      toolbarMode: toolbarMode ?? this.toolbarMode,
      toolState: nextToolState,
    );
  }

  BuildingPageToolState _copyToolStateWithSelection(
    BuildingPageToolState value, {
    required String? selectedListeningAreaId,
    required String? selectedSpeakerId,
    required bool clearSelectedListeningAreaId,
    required bool clearSelectedSpeakerId,
  }) {
    if (value case final SelectToolState tool) {
      return tool.copyWith(
        selectedListeningAreaId: selectedListeningAreaId,
        selectedSpeakerId: selectedSpeakerId,
        clearSelectedListeningAreaId: clearSelectedListeningAreaId,
        clearSelectedSpeakerId: clearSelectedSpeakerId,
      );
    }
    if (value case final SpeakerPlacementState tool) {
      return tool.copyWith(
        selectedListeningAreaId: selectedListeningAreaId,
        selectedSpeakerId: selectedSpeakerId,
        clearSelectedListeningAreaId: clearSelectedListeningAreaId,
        clearSelectedSpeakerId: clearSelectedSpeakerId,
      );
    }
    return value;
  }

  @override
  bool operator ==(covariant BuildingPageState other) {
    if (identical(this, other)) return true;

    return other.toolbarMode == toolbarMode &&
        other.toolState == toolState &&
        other.selectedListeningAreaId == selectedListeningAreaId &&
        other.selectedSpeakerId == selectedSpeakerId;
  }

  @override
  int get hashCode => Object.hash(toolbarMode, toolState, selectedListeningAreaId, selectedSpeakerId);

  static BuildingPageState defaultAcousticsState() {
    return BuildingPageState(
      toolbarMode: ToolbarMode.acoustics,
      toolState: SelectToolState(),
    );
  }

  static BuildingPageState defaultSystemState() {
    return BuildingPageState(
      toolbarMode: ToolbarMode.system,
      toolState: SystemToolState(),
    );
  }
}

abstract class BuildingPageToolState {}

class SystemToolState extends BuildingPageToolState {}

class DrawingListingAreaState extends BuildingPageToolState {}

class MeasuringToolState extends BuildingPageToolState {}

class SelectToolState extends BuildingPageToolState {
  final String? selectedListeningAreaId;
  final String? selectedSpeakerId;

  SelectToolState({this.selectedListeningAreaId, this.selectedSpeakerId});

  SelectToolState copyWith({
    String? selectedListeningAreaId,
    String? selectedSpeakerId,
    bool clearSelectedListeningAreaId = false,
    bool clearSelectedSpeakerId = false,
  }) {
    return SelectToolState(
      selectedListeningAreaId: clearSelectedListeningAreaId ? null : selectedListeningAreaId ?? this.selectedListeningAreaId,
      selectedSpeakerId: clearSelectedSpeakerId ? null : selectedSpeakerId ?? this.selectedSpeakerId,
    );
  }

  @override
  bool operator ==(covariant BuildingPageToolState other) {
    if (identical(this, other)) return true;
    return other is SelectToolState && other.selectedListeningAreaId == selectedListeningAreaId && other.selectedSpeakerId == selectedSpeakerId;
  }

  @override
  int get hashCode => Object.hash(selectedListeningAreaId, selectedSpeakerId);
}

class SplToolState extends BuildingPageToolState {}

class SpeakerPlacementState extends BuildingPageToolState {
  final String? selectedListeningAreaId;
  final String? selectedSpeakerId;

  SpeakerPlacementState({this.selectedListeningAreaId, this.selectedSpeakerId});

  SpeakerPlacementState copyWith({
    String? selectedListeningAreaId,
    String? selectedSpeakerId,
    bool clearSelectedListeningAreaId = false,
    bool clearSelectedSpeakerId = false,
  }) {
    return SpeakerPlacementState(
      selectedListeningAreaId: clearSelectedListeningAreaId ? null : selectedListeningAreaId ?? this.selectedListeningAreaId,
      selectedSpeakerId: clearSelectedSpeakerId ? null : selectedSpeakerId ?? this.selectedSpeakerId,
    );
  }

  @override
  bool operator ==(covariant BuildingPageToolState other) {
    if (identical(this, other)) return true;
    return other is SpeakerPlacementState && other.selectedListeningAreaId == selectedListeningAreaId && other.selectedSpeakerId == selectedSpeakerId;
  }

  @override
  int get hashCode => Object.hash(selectedListeningAreaId, selectedSpeakerId);
}

class AddSourceState extends BuildingPageToolState {}
