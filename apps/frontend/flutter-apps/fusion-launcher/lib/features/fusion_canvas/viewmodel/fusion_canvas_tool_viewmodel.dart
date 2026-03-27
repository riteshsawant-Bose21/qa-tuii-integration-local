import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_hover_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/drag_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/select_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';

import '../state/fusion_canvas_input_state.dart';
import '../state/fusion_snap_state.dart';
import '../state/fusion_tool_state.dart';
import '../state/tools/measure_tool_state.dart';
import '../state/tools/pen_tool_state.dart';
import '../view/painters/elements/mixin/fusion_canvas_interactable_mixin.dart';
import 'tool_helper/drag_tool_helper.dart';
import 'tool_helper/measure_tool_helper.dart';
import 'tool_helper/pen_tool_helper.dart';
import 'tool_helper/selection_tool_helper.dart';

typedef FusionCanvasInteractionResolver =
    FusionCanvasInteractionTarget? Function(
      Offset position,
      FusionCanvasLayerInteraction interaction,
    );

typedef FusionCanvasBoundedDeltaResolver =
    Offset Function(
      String layerId,
      Offset delta,
    );

typedef FusionCanvasLayerInteractionSupportResolver =
    bool Function(
      String layerId,
      FusionCanvasLayerInteraction interaction,
    );

/// Context containing all information needed for input state handling
class FusionCanvasInputContext {
  final FusionHoverState hoverState;
  final FusionSnapState snapState;
  final FusionCanvasInputState inputState;
  final FusionCanvasInteractionResolver resolveInteractionTargetAt;
  final FusionCanvasBoundedDeltaResolver resolveBoundedDeltaForLayer;
  final FusionCanvasLayerInteractionSupportResolver supportsLayerInteraction;

  const FusionCanvasInputContext({
    required this.hoverState,
    required this.snapState,
    required this.inputState,
    required this.resolveInteractionTargetAt,
    required this.resolveBoundedDeltaForLayer,
    required this.supportsLayerInteraction,
  });
}

class FusionCanvasToolViewModel extends Cubit<FusionToolState> {
  FusionCanvasToolViewModel() : super(IdleSelectToolState());

  // Tool helpers
  final MeasureToolHelper _measureToolHelper = MeasureToolHelper();
  final PenToolHelper _penToolHelper = PenToolHelper();
  final SelectionToolHelper _selectionToolHelper = SelectionToolHelper();
  final DragToolHelper _dragToolHelper = DragToolHelper();

  ///
  /// Returns true if the event was handled by the tool viewmodel.
  ///
  ///
  bool onInputStateChanged(
    FusionCanvasInputState inputState,
    FusionCanvasInputContext context,
  ) {
    // Delegate to tool-specific helpers based on current state
    final FusionToolState? newState = _transformWithHelper(inputState, context);
    if (newState != null && newState != state) {
      // print("State changed: $state   ==> $newState. on inputState: $inputState");
      emit(newState);
      return true;
    }
    return false;
  }

  /// Transform state using tool-specific helpers
  FusionToolState? _transformWithHelper(
    FusionCanvasInputState inputState,
    FusionCanvasInputContext context,
  ) {
    final FusionToolState currentState = state;
    if (currentState is MeasureToolState) {
      return _measureToolHelper.transform(
        inputState: inputState,
        context: context,
        currentState: currentState,
      );
    }

    if (currentState is PenToolState) {
      return _penToolHelper.transform(
        inputState: inputState,
        context: context,
        currentState: currentState,
      );
    }

    if (currentState is DragToolState) {
      return _dragToolHelper.transform(
        inputState: inputState,
        context: context,
        currentState: currentState,
      );
    }

    if (currentState is SelectToolState) {
      return _selectionToolHelper.transform(
        inputState: inputState,
        context: context,
        currentState: currentState,
      );
    }

    return null;
  }

  void setTool(FusionToolState toolState) {
    emit(toolState);
  }

  // ==================== Selection Operations ====================

  /// Get current selected layer IDs
  Set<String> get selectedLayerIds {
    final FusionToolState currentState = state;
    if (currentState is SelectToolState) {
      return currentState.selectedLayerIds;
    }
    return <String>{};
  }

  /// Get current selected element IDs
  Set<String> get selectedElementIds {
    final FusionToolState currentState = state;
    if (currentState is SelectToolState) {
      return currentState.selectedElementIds;
    }
    return <String>{};
  }

  /// Update selection from external source (sync with provided IDs)
  void syncSelection(Set<String> layerIds) {
    if (state is SelectToolState) {
      final Set<String> existing = (state as SelectToolState).selectedLayerIds;
      if (!setEquals(existing, layerIds)) {
        print("Syncing selection with external source: $layerIds");
        emit(IdleSelectToolState(selectedLayerIds: layerIds));
      }
    }
  }
}
