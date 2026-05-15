// ignore_for_file: public_member_api_docs, sort_constructors_first
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
    if (toolState case SplSelectToolState(:final String? selectedListeningAreaId)) {
      return selectedListeningAreaId;
    }
    if (toolState case SystemSelectToolState(:final String? selectedListeningAreaId)) {
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
    if (toolState case SplSelectToolState(:final String? selectedSpeakerId)) {
      return selectedSpeakerId;
    }
    if (toolState case SystemSelectToolState(:final String? selectedSpeakerId)) {
      return selectedSpeakerId;
    }
    return null;
  }

  String? get selectedWallId {
    if (toolState case WallSelectToolState(:final String? selectedWallId)) {
      return selectedWallId;
    }
    if (toolState case SelectToolState(:final String? selectedWallId)) {
      return selectedWallId;
    }
    if (toolState case SplSelectToolState(:final String? selectedWallId)) {
      return selectedWallId;
    }
    if (toolState case SystemSelectToolState(:final String? selectedWallId)) {
      return selectedWallId;
    }
    return null;
  }

  String? get selectedCircuitId {
    if (toolState case SelectToolState(:final String? selectedCircuitId)) {
      return selectedCircuitId;
    }
    if (toolState case SplSelectToolState(:final String? selectedCircuitId)) {
      return selectedCircuitId;
    }
    if (toolState case SystemSelectToolState(:final String? selectedCircuitId)) {
      return selectedCircuitId;
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
    bool clearSelectedWallId = false,
    String? selectedWallId,
    bool clearSelectedCircuitId = false,
    String? selectedCircuitId,
  }) {
    final String? nextListeningAreaId = clearSelectedListeningAreaId ? null : selectedListeningAreaId ?? this.selectedListeningAreaId;
    final String? nextSpeakerId = clearSelectedSpeakerId ? null : selectedSpeakerId ?? this.selectedSpeakerId;
    final String? nextWallId = clearSelectedWallId ? null : selectedWallId ?? this.selectedWallId;
    final String? nextCircuitId = clearSelectedCircuitId ? null : selectedCircuitId ?? this.selectedCircuitId;

    final BuildingPageToolState nextToolState = _copyToolStateWithSelection(
      toolState ?? this.toolState,
      selectedListeningAreaId: nextListeningAreaId,
      selectedSpeakerId: nextSpeakerId,
      clearSelectedListeningAreaId: clearSelectedListeningAreaId,
      clearSelectedSpeakerId: clearSelectedSpeakerId,
      selectedWallId: nextWallId,
      clearSelectedWallId: clearSelectedWallId,
      selectedCircuitId: nextCircuitId,
      clearSelectedCircuitId: clearSelectedCircuitId,
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
    required String? selectedWallId,
    required String? selectedCircuitId,
    required bool clearSelectedListeningAreaId,
    required bool clearSelectedSpeakerId,
    required bool clearSelectedWallId,
    required bool clearSelectedCircuitId,
  }) {
    if (value case final SelectToolState tool) {
      return tool.copyWith(
        selectedListeningAreaId: selectedListeningAreaId,
        selectedSpeakerId: selectedSpeakerId,
        selectedCircuitId: selectedCircuitId,
        clearSelectedListeningAreaId: clearSelectedListeningAreaId,
        clearSelectedSpeakerId: clearSelectedSpeakerId,
        clearSelectedWallId: clearSelectedWallId,
        clearSelectedCircuitId: clearSelectedCircuitId,
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
    if (value case final WallSelectToolState tool) {
      return tool.copyWith(
        selectedWallId: selectedWallId,
        clearSelectedWallId: clearSelectedWallId,
      );
    }
    if (value case final SplSelectToolState tool) {
      return tool.copyWith(
        selectedCircuitId: selectedCircuitId,
        clearSelectedCircuitId: clearSelectedCircuitId,
      );
    }
    if (value case final SystemSelectToolState tool) {
      return tool.copyWith(
        selectedCircuitId: selectedCircuitId,
        clearSelectedCircuitId: clearSelectedCircuitId,
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
        other.selectedSpeakerId == selectedSpeakerId &&
        other.selectedWallId == selectedWallId &&
        other.selectedCircuitId == selectedCircuitId;
  }

  @override
  int get hashCode => Object.hash(toolbarMode, toolState, selectedListeningAreaId, selectedSpeakerId, selectedWallId, selectedCircuitId);

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

class MeasuringToolState extends BuildingPageToolState {}

abstract class SplToolState extends BuildingPageToolState {}

class IdleSplToolState extends SplToolState {}

class SplSelectToolState extends SplToolState {
  final String? selectedListeningAreaId;
  final String? selectedSpeakerId;
  final String? selectedWallId;
  final String? selectedCircuitId;

  SplSelectToolState({this.selectedListeningAreaId, this.selectedSpeakerId, this.selectedWallId, this.selectedCircuitId});

  SplSelectToolState copyWith({
    String? selectedListeningAreaId,
    String? selectedSpeakerId,
    String? selectedWallId,
    String? selectedCircuitId,
    bool clearSelectedListeningAreaId = false,
    bool clearSelectedSpeakerId = false,
    bool clearSelectedWallId = false,
    bool clearSelectedCircuitId = false,
  }) {
    return SplSelectToolState(
      selectedListeningAreaId: clearSelectedListeningAreaId ? null : selectedListeningAreaId ?? this.selectedListeningAreaId,
      selectedSpeakerId: clearSelectedSpeakerId ? null : selectedSpeakerId ?? this.selectedSpeakerId,
      selectedWallId: clearSelectedWallId ? null : selectedWallId ?? this.selectedWallId,
      selectedCircuitId: clearSelectedCircuitId ? null : selectedCircuitId ?? this.selectedCircuitId,
    );
  }

  @override
  bool operator ==(covariant BuildingPageToolState other) {
    if (identical(this, other)) return true;
    return other is SplSelectToolState &&
        other.selectedListeningAreaId == selectedListeningAreaId &&
        other.selectedSpeakerId == selectedSpeakerId &&
        other.selectedWallId == selectedWallId &&
        other.selectedCircuitId == selectedCircuitId;
  }

  @override
  int get hashCode => Object.hash(selectedListeningAreaId, selectedSpeakerId, selectedWallId, selectedCircuitId);
}

abstract class ListeningAreaToolState extends BuildingPageToolState {}

class DrawingListeningAreaState extends ListeningAreaToolState {
  final String? listeningAreaId;

  DrawingListeningAreaState({required this.listeningAreaId});

  @override
  bool operator ==(covariant BuildingPageToolState other) {
    if (identical(this, other)) return true;

    return other is DrawingListeningAreaState && other.listeningAreaId == listeningAreaId;
  }

  @override
  int get hashCode => listeningAreaId.hashCode;
}

class DrawingRectangleListeningAreaState extends ListeningAreaToolState {
  final String? listeningAreaId;

  DrawingRectangleListeningAreaState({required this.listeningAreaId});

  @override
  bool operator ==(covariant BuildingPageToolState other) {
    if (identical(this, other)) return true;

    return other is DrawingRectangleListeningAreaState && other.listeningAreaId == listeningAreaId;
  }

  @override
  int get hashCode => listeningAreaId.hashCode;
}

class SelectToolState extends ListeningAreaToolState {
  final String? selectedListeningAreaId;
  final String? selectedSpeakerId;
  final String? selectedWallId;
  final String? selectedCircuitId;

  SelectToolState({this.selectedListeningAreaId, this.selectedSpeakerId, this.selectedWallId, this.selectedCircuitId});

  SelectToolState copyWith({
    String? selectedListeningAreaId,
    String? selectedSpeakerId,
    String? selectedWallId,
    String? selectedCircuitId,
    bool clearSelectedListeningAreaId = false,
    bool clearSelectedSpeakerId = false,
    bool clearSelectedWallId = false,
    bool clearSelectedCircuitId = false,
  }) {
    return SelectToolState(
      selectedListeningAreaId: clearSelectedListeningAreaId ? null : selectedListeningAreaId ?? this.selectedListeningAreaId,
      selectedSpeakerId: clearSelectedSpeakerId ? null : selectedSpeakerId ?? this.selectedSpeakerId,
      selectedWallId: clearSelectedWallId ? null : selectedWallId ?? this.selectedWallId,
      selectedCircuitId: clearSelectedCircuitId ? null : selectedCircuitId ?? this.selectedCircuitId,
    );
  }

  @override
  bool operator ==(covariant BuildingPageToolState other) {
    if (identical(this, other)) return true;
    return other is SelectToolState &&
        other.selectedListeningAreaId == selectedListeningAreaId &&
        other.selectedSpeakerId == selectedSpeakerId &&
        other.selectedWallId == selectedWallId &&
        other.selectedCircuitId == selectedCircuitId;
  }

  @override
  int get hashCode => Object.hash(selectedListeningAreaId, selectedSpeakerId, selectedWallId, selectedCircuitId);
}

class SpeakerPlacementState extends ListeningAreaToolState {
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

abstract class WallToolState extends BuildingPageToolState {}

class DrawingWallState extends WallToolState {
  final String? wallId;

  DrawingWallState({required this.wallId});

  @override
  bool operator ==(covariant BuildingPageToolState other) {
    if (identical(this, other)) return true;

    return other is DrawingWallState && other.wallId == wallId;
  }

  @override
  int get hashCode => wallId.hashCode;
}

class WallSelectToolState extends WallToolState {
  final String? selectedWallId;

  WallSelectToolState({this.selectedWallId});

  WallSelectToolState copyWith({
    String? selectedWallId,
    bool clearSelectedWallId = false,
  }) {
    return WallSelectToolState(
      selectedWallId: clearSelectedWallId ? null : selectedWallId ?? this.selectedWallId,
    );
  }

  @override
  bool operator ==(covariant BuildingPageToolState other) {
    if (identical(this, other)) return true;
    return other is WallSelectToolState && other.selectedWallId == selectedWallId;
  }

  @override
  int get hashCode => selectedWallId.hashCode;
}

class SystemSelectToolState extends SystemToolState {
  final String? selectedListeningAreaId;
  final String? selectedSpeakerId;
  final String? selectedWallId;
  final String? selectedCircuitId;

  SystemSelectToolState({this.selectedListeningAreaId, this.selectedSpeakerId, this.selectedWallId, this.selectedCircuitId});

  SystemSelectToolState copyWith({
    String? selectedListeningAreaId,
    String? selectedSpeakerId,
    String? selectedWallId,
    String? selectedCircuitId,
    bool clearSelectedListeningAreaId = false,
    bool clearSelectedSpeakerId = false,
    bool clearSelectedWallId = false,
    bool clearSelectedCircuitId = false,
  }) {
    return SystemSelectToolState(
      selectedListeningAreaId: clearSelectedListeningAreaId ? null : selectedListeningAreaId ?? this.selectedListeningAreaId,
      selectedSpeakerId: clearSelectedSpeakerId ? null : selectedSpeakerId ?? this.selectedSpeakerId,
      selectedWallId: clearSelectedWallId ? null : selectedWallId ?? this.selectedWallId,
      selectedCircuitId: clearSelectedCircuitId ? null : selectedCircuitId ?? this.selectedCircuitId,
    );
  }

  @override
  bool operator ==(covariant BuildingPageToolState other) {
    if (identical(this, other)) return true;
    return other is SystemSelectToolState &&
        other.selectedListeningAreaId == selectedListeningAreaId &&
        other.selectedSpeakerId == selectedSpeakerId &&
        other.selectedWallId == selectedWallId &&
        other.selectedCircuitId == selectedCircuitId;
  }

  @override
  int get hashCode => Object.hash(selectedListeningAreaId, selectedSpeakerId, selectedWallId, selectedCircuitId);
}
