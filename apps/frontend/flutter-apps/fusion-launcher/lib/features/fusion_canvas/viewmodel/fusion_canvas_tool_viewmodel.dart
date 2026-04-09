import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_hover_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/select_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/tools/fusion_canvas_tool.dart';

import '../state/fusion_canvas_input_state.dart';
import '../state/fusion_snap_state.dart';
import '../state/fusion_tool_state.dart';

/// Context containing all information needed for input state handling
class FusionCanvasInputContext {
  final FusionHoverState hoverState;
  final FusionSnapState snapState;
  final FusionCanvasInputState inputState;
  // final SelectionToolParams selectionToolParams;
  final FusionCanvasPainter fusionCanvasPainter;

  const FusionCanvasInputContext({
    required this.hoverState,
    required this.snapState,
    required this.inputState,
    // required this.selectionToolParams,
    required this.fusionCanvasPainter,
  });
}

class FusionCanvasToolViewModel extends Cubit<FusionToolState> {
  FusionCanvasToolViewModel() : super(IdleSelectToolState());

  // final List<FusionCanvasTool<FusionToolState>> _tools = <FusionCanvasTool<FusionToolState>>[
  //   FusionCanvasTool.measureTool,
  //   FusionCanvasTool.penTool,
  //   FusionCanvasTool.dragTool,
  //   FusionCanvasTool.selectionTool,
  // ];

  ///
  ///
  /// Returns true if the event was handled by the tool viewmodel.
  ///
  ///
  bool onInputStateChanged(
    FusionCanvasInputState inputState,
    FusionCanvasInputContext context,
    List<FusionCanvasTool<FusionToolState>> tools,
  ) {
    // Delegate to tool-specific helpers based on current state
    final FusionToolState? newState = _transformWithHelper(inputState, context, tools);
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
    List<FusionCanvasTool<FusionToolState>> tools,
  ) {
    final FusionToolState currentState = state;
    for (final FusionCanvasTool<FusionToolState> tool in tools) {
      if (tool.canHandleState(currentState)) {
        return tool.transformer.transform(inputState: inputState, context: context, currentState: currentState);
      }
    }
    // if (currentState is MeasureToolState) {
    //   return _measureToolHelper.transform(
    //     inputState: inputState,
    //     context: context,
    //     currentState: currentState,
    //   );
    // }

    // if (currentState is PenToolState) {
    //   return _penToolHelper.transform(
    //     inputState: inputState,
    //     context: context,
    //     currentState: currentState,
    //   );
    // }

    // if (currentState is DragToolState) {
    //   return _dragToolHelper.transform(
    //     inputState: inputState,
    //     context: context,
    //     currentState: currentState,
    //   );
    // }

    // if (currentState is SelectToolState) {
    //   return _selectionToolHelper.transform(
    //     inputState: inputState,
    //     context: context,
    //     currentState: currentState,
    //   );
    // }

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
    if (state is MarqueeSelectToolState) return;

    if (state is SelectToolState) {
      final Set<String> existing = (state as SelectToolState).selectedLayerIds;
      if (!setEquals(existing, layerIds)) {
        print("Syncing selection with external source: $layerIds");
        emit(IdleSelectToolState(selectedLayerIds: layerIds));
      }
    }
  }
}
