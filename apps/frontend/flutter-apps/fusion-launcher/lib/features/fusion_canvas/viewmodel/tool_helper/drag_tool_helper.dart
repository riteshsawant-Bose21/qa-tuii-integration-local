import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/drag_tool_state.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../state/fusion_canvas_input_state.dart';
import '../../state/fusion_snap_state.dart';
import '../../state/tools/select_tool_state.dart';
import '../../view/painters/elements/mixin/fusion_canvas_interactable_mixin.dart';
import '../fusion_canvas_tool_viewmodel.dart';

class DragToolHelper {
  FusionToolState transform({
    required FusionCanvasInputState inputState,
    required FusionCanvasInputContext context,
    required DragToolState currentState,
  }) {
    if (inputState is FusionCanvasInputTapDownState) {
      return _handleTapDown(inputState, context, currentState);
    }

    if (inputState is FusionCanvasInputDraggingState) {
      return _handleDragging(inputState, context, currentState);
    }

    if (inputState is FusionCanvasInputTapUpState) {
      if (inputState.gestureOrigin == FusionGestureOrigin.drag) {
        return _handleDragEnd(context, currentState);
      } else if (inputState.gestureOrigin == FusionGestureOrigin.click && inputState.button == FusionMouseButton.left) {
        // Handle click gestures for selection
        final String? hoveredPainterId = context.hoverState.hoveredPainterId;
        final String? hoveredElementId = context.hoverState.hoveredElement?.id;

        if (hoveredPainterId != null && context.hoverState.supportsInteraction(FusionCanvasLayerInteraction.select)) {
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

    return currentState;
  }

  FusionToolState _handleTapDown(
    FusionCanvasInputTapDownState inputState,
    FusionCanvasInputContext context,
    DragToolState currentState,
  ) {
    final String? hoveredPainterId = context.hoverState.hoveredPainterId;

    if (hoveredPainterId != null && context.hoverState.supportsInteraction(FusionCanvasLayerInteraction.drag)) {
      // User tapped on an element - determine if it's points or layer drag
      final List<FusionCanvasElement> elements =
          context.hoverState.hoveredElement != null && context.hoverState.hoveredElement!.pointIds.isNotEmpty
              ? <FusionCanvasElement>[context.hoverState.hoveredElement!]
              : <FusionCanvasElement>[];

      if (elements.isNotEmpty) {
        return PointsDragStartState(layerId: hoveredPainterId, elements: elements);
      } else {
        return LayerDragStartState(layerId: hoveredPainterId);
      }
    } else {
      // User tapped on empty canvas - so ignore.
      return currentState;
    }
  }

  FusionToolState _handleDragging(
    FusionCanvasInputDraggingState inputState,
    FusionCanvasInputContext context,
    DragToolState currentState,
  ) {
    final Offset delta = inputState.delta;

    if (currentState is LayerDragStartState) {
      final Offset boundedDelta = context.resolveBoundedDeltaForLayer(
        currentState.layerId,
        delta,
      );
      return LayerDraggingState(layerId: currentState.layerId, delta: boundedDelta);
    } else if (currentState is LayerDraggingState) {
      final Offset boundedDelta = context.resolveBoundedDeltaForLayer(
        currentState.layerId,
        currentState.delta + delta,
      );
      return LayerDraggingState(
        layerId: currentState.layerId,
        delta: boundedDelta,
      );
    }

    if (currentState is PointsDragStartState) {
      final Offset boundedDelta = context.resolveBoundedDeltaForLayer(
        currentState.layerId,
        delta,
      );
      return PointsDraggingState(
        layerId: currentState.layerId,
        elements: currentState.elements,
        delta: boundedDelta,
      );
    } else if (currentState is PointsDraggingState) {
      final Offset boundedDelta = context.resolveBoundedDeltaForLayer(
        currentState.layerId,
        currentState.delta + delta,
      );
      return PointsDraggingState(
        layerId: currentState.layerId,
        elements: currentState.elements,
        delta: boundedDelta,
      );
    }

    return currentState;
  }

  FusionToolState _handleDragEnd(
    FusionCanvasInputContext context,
    DragToolState currentState,
  ) {
    // Calculate snap adjustment if snapping is active
    final Offset snapAdjustment = _calculateSnapAdjustment(context.snapState);

    if (currentState is LayerDraggingState) {
      final Offset boundedDelta = context.resolveBoundedDeltaForLayer(
        currentState.layerId,
        currentState.delta + snapAdjustment,
      );
      return LayerDragEndState(
        layerId: currentState.layerId,
        delta: boundedDelta,
      );
    } else if (currentState is PointsDraggingState) {
      final Offset boundedDelta = context.resolveBoundedDeltaForLayer(
        currentState.layerId,
        currentState.delta + snapAdjustment,
      );
      return PointsDragEndState(
        layerId: currentState.layerId,
        elements: currentState.elements,
        delta: boundedDelta,
      );
    }

    return IdleSelectToolState();
  }

  Offset _calculateSnapAdjustment(FusionSnapState snapState) {
    if (snapState.isSnapped && snapState.cursorPositions != null && snapState.snapResult?.cursorIndex != null) {
      final int cursorIndex = snapState.snapResult!.cursorIndex!;
      if (cursorIndex < snapState.cursorPositions!.length) {
        final Offset currentPosition = snapState.cursorPositions![cursorIndex];
        final Offset snappedPosition = snapState.snapResult!.snappedPosition;
        return snappedPosition - currentPosition;
      }
    }
    return Offset.zero;
  }
}
