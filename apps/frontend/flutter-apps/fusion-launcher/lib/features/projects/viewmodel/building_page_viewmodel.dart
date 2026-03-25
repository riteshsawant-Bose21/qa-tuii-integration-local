import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_canvas_input_state.dart';
import 'package:fusion_launcher/features/projects/viewmodel/building_page_state.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../configuration/presentation/viewmodel/project_view_model.dart';

class BuildingPageViewModel extends Cubit<BuildingPageState> {
  final ProjectViewModel _projectViewModel;
  late final StreamSubscription<ProjectViewModelState> _projectViewModelSubscription;

  BuildingPageViewModel({required ProjectViewModel projectViewModel})
    : _projectViewModel = projectViewModel,
      super(
        BuildingPageState.defaultAcousticsState().copyWith(
          selectedListeningAreaId: projectViewModel.currentSelectedListeningAreaId,
          selectedSpeakerId: projectViewModel.currentSelectedHardwareId,
        ),
      ) {
    _projectViewModelSubscription = _projectViewModel.stream.listen((ProjectViewModelState _) {
      _syncSelectionFromProject();
    });
  }

  void toggleMode(ToolbarMode mode) {
    if (mode == ToolbarMode.acoustics) {
      emit(
        state.copyWith(
          toolbarMode: ToolbarMode.acoustics,
          toolState: _defaultToolForMode(
            SelectToolState(),
            selectedListeningAreaId: _projectViewModel.currentSelectedListeningAreaId,
            selectedSpeakerId: _projectViewModel.currentSelectedHardwareId,
          ),
        ),
      );
    } else {
      emit(
        state.copyWith(
          toolbarMode: ToolbarMode.system,
          toolState: _defaultToolForMode(
            SystemSelectToolState(),
            selectedListeningAreaId: _projectViewModel.currentSelectedListeningAreaId,
            selectedSpeakerId: _projectViewModel.currentSelectedHardwareId,
          ),
        ),
      );
    }
  }

  void setTool(BuildingPageToolState toolState) {
    emit(state.copyWith(toolState: _toolStateWithProjectSelection(toolState)));
  }

  // void addSourceState() {
  //   emit(state.copyWith(toolState: AddSourceState()));
  // }

  void cancelState() {
    emit(
      state.copyWith(
        toolState: _defaultToolForMode(state.toolState),
      ),
    );
  }

  void setShouldPlaceNonPlacedSpeakers(bool shouldPlace) {
    if (state.toolState is SpeakerPlacementState) {
      if (!shouldPlace) {
        cancelState();
      }
    } else {
      if (shouldPlace) {
        setTool(
          SpeakerPlacementState(
            selectedListeningAreaId: _projectViewModel.currentSelectedListeningAreaId,
            selectedSpeakerId: _projectViewModel.currentSelectedHardwareId,
          ),
        );
      }
    }
  }

  bool get isSpeakerPlacementMode => state.toolState is SpeakerPlacementState;

  bool get isSplMode {
    return state.toolState is SplToolState;
  }

  bool get isAcousticsMode => state.toolbarMode == ToolbarMode.acoustics;

  bool get isSystemMode => state.toolbarMode == ToolbarMode.system;

  bool get canAddSpeakerFromCanvas => isSpeakerPlacementMode;

  bool canPlaceSpeakerOnMouseUp(FusionCanvasInputTapUpState event) {
    return isSpeakerPlacementMode && event.gestureOrigin == FusionGestureOrigin.click;
  }

  void onSpeakerPlaced({required bool hasPendingSpeakers}) {
    if (!hasPendingSpeakers) {
      setShouldPlaceNonPlacedSpeakers(false);
    }
  }

  void cancelSpeakerPlacementIfActive() {
    if (isSpeakerPlacementMode) {
      cancelState();
    }
  }

  void _syncSelectionFromProject() {
    final String? nextListeningAreaId = _projectViewModel.currentSelectedListeningAreaId;
    final String? nextSpeakerId = _projectViewModel.currentSelectedHardwareId;

    final bool listeningAreaChanged = state.selectedListeningAreaId != nextListeningAreaId;
    final bool speakerChanged = state.selectedSpeakerId != nextSpeakerId;

    if (!listeningAreaChanged && !speakerChanged) {
      return;
    }

    final BuildingPageToolState nextToolState =
    // listeningAreaChanged && isSpeakerPlacementMode
    // ?
    _defaultToolForMode(
      state.toolState,
      selectedListeningAreaId: nextListeningAreaId,
      selectedSpeakerId: nextSpeakerId,
    );
    // : state.toolState;

    final BuildingPageState copyWith = state.copyWith(
      toolState: nextToolState,
      selectedListeningAreaId: nextListeningAreaId,
      selectedSpeakerId: nextSpeakerId,
      clearSelectedListeningAreaId: listeningAreaChanged && nextListeningAreaId == null,
      clearSelectedSpeakerId: speakerChanged && nextSpeakerId == null,
    );
    emit(
      copyWith,
    );
  }

  BuildingPageToolState _defaultToolForMode(
    BuildingPageToolState mode, {
    String? selectedListeningAreaId,
    String? selectedSpeakerId,
  }) {
    if (mode is SplToolState) {
      return SplSelectToolState(
        selectedListeningAreaId: selectedListeningAreaId,
        selectedSpeakerId: selectedSpeakerId,
      );
    }
    if (mode is SystemSelectToolState) {
      return SystemSelectToolState(
        selectedListeningAreaId: selectedListeningAreaId,
        selectedSpeakerId: selectedSpeakerId,
      );
    }
    // if (mode == ToolbarMode.acoustics) {

    return SelectToolState(
      selectedListeningAreaId: selectedListeningAreaId,
      selectedSpeakerId: selectedSpeakerId,
    );
    // }
    // return SystemToolState();
  }

  BuildingPageToolState _toolStateWithProjectSelection(BuildingPageToolState toolState) {
    final String? selectedListeningAreaId = _projectViewModel.currentSelectedListeningAreaId;
    final String? selectedSpeakerId = _projectViewModel.currentSelectedHardwareId;

    if (toolState case final SelectToolState value) {
      return value.copyWith(
        selectedListeningAreaId: selectedListeningAreaId,
        selectedSpeakerId: selectedSpeakerId,
        clearSelectedListeningAreaId: selectedListeningAreaId == null,
        clearSelectedSpeakerId: selectedSpeakerId == null,
      );
    }

    if (toolState case final SpeakerPlacementState value) {
      return value.copyWith(
        selectedListeningAreaId: selectedListeningAreaId,
        selectedSpeakerId: selectedSpeakerId,
        clearSelectedListeningAreaId: selectedListeningAreaId == null,
        clearSelectedSpeakerId: selectedSpeakerId == null,
      );
    }

    return toolState;
  }

  @override
  Future<void> close() async {
    await _projectViewModelSubscription.cancel();
    return super.close();
  }

  SpeakerPlacementCursorState? getSpeakerPlacementCursorState() {
    if (!isSpeakerPlacementMode) {
      return null;
    }
    try {
      final List<Speaker> nonPlacedSpeakers = _projectViewModel.getNonPlacedSpeakersForCurrentListeningArea();
      if (!isSpeakerPlacementMode || nonPlacedSpeakers.isEmpty) {
        return null;
      }
      return SpeakerPlacementCursorState(
        mountingType: nonPlacedSpeakers.first.mountingType,
        pendingCount: nonPlacedSpeakers.length,
      );
    } catch (e) {}
    return null;
  }
}

class SpeakerPlacementCursorState {
  final MountingType? mountingType;
  final int pendingCount;

  const SpeakerPlacementCursorState({required this.mountingType, required this.pendingCount});
}
