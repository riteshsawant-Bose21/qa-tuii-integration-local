import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/drag_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/select_tool_state.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../state/fusion_canvas_input_state.dart';
import '../fusion_canvas_tool_viewmodel.dart';

class SelectionToolHelper {
  FusionToolState transform({
    required FusionCanvasInputState inputState,
    required FusionCanvasInputContext context,
    required SelectToolState currentState,
  }) {
    if (inputState is FusionCanvasInputTapDownState) {
      return _handleTapDown(context, currentState);
    }

    if (inputState is FusionCanvasInputDraggingState) {
      return _handleDragging(inputState, context, currentState);
    }

    if (inputState is FusionCanvasInputTapUpState) {
      // Handle click gestures for selection
      if (inputState.gestureOrigin == FusionGestureOrigin.click && inputState.button == FusionMouseButton.left) {
        return _handleClick(context, currentState);
      }
    }

    if (inputState is FusionCanvasInputSecondaryTapState) {
      // Right-click clears selection
      return IdleSelectToolState();
    }

    return currentState;
  }

  FusionToolState _handleTapDown(
    FusionCanvasInputContext context,
    SelectToolState currentState,
  ) {
    final String? hoveredPainterId = context.hoverState.hoveredPainterId;

    if (hoveredPainterId != null) {
      // User tapped on an element - prepare for potential drag
      final List<FusionCanvasElement> elements =
          context.hoverState.hoveredElement != null ? <FusionCanvasElement>[context.hoverState.hoveredElement!] : <FusionCanvasElement>[];

      if (elements.isNotEmpty) {
        return PointsDragStartState(layerId: hoveredPainterId, elements: elements);
      } else {
        return LayerDragStartState(layerId: hoveredPainterId);
      }
    } else {
      // Tapped on empty canvas - start panning
      return currentState;
      // CanvasPanningState(delta: Offset.zero);
    }
  }

  FusionToolState _handleDragging(
    FusionCanvasInputDraggingState inputState,
    FusionCanvasInputContext context,
    SelectToolState currentState,
  ) {
    final Offset delta = inputState.delta;

    // If we have selected layers, drag the first one
    if (currentState.selectedLayerIds.isNotEmpty && inputState.button == FusionMouseButton.left) {
      return LayerDraggingState(
        layerId: currentState.selectedLayerIds.first,
        delta: delta,
      );
    }

    // Otherwise, pan the canvas
    return currentState;
  }

  FusionToolState _handleClick(
    FusionCanvasInputContext context,
    SelectToolState currentState,
  ) {
    final String? hoveredPainterId = context.hoverState.hoveredPainterId;
    final String? hoveredElementId = context.hoverState.hoveredElement?.id;

    if (hoveredPainterId != null) {
      // Clicked on a layer - select it
      return IdleSelectToolState(
        selectedLayerIds: <String>{hoveredPainterId},
        selectedElementIds: hoveredElementId != null ? <String>{hoveredElementId} : <String>{},
      );
    } else {
      // Clicked on empty canvas - clear selection
      return IdleSelectToolState();
    }
  }
}
