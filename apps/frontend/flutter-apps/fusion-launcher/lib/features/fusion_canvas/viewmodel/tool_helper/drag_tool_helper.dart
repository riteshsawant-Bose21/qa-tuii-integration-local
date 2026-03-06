import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/drag_tool_state.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../state/fusion_canvas_input_state.dart';
import '../../state/fusion_snap_state.dart';
import '../../state/tools/select_tool_state.dart';
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
      return _handleDragging(inputState, currentState);
    }

    if (inputState is FusionCanvasInputTapUpState) {
      if (inputState.gestureOrigin == FusionGestureOrigin.drag) {
        return _handleDragEnd(context.snapState, currentState);
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

    if (hoveredPainterId != null) {
      // User tapped on an element - determine if it's points or layer drag
      final List<FusionCanvasElement> elements =
          context.hoverState.hoveredElement != null ? <FusionCanvasElement>[context.hoverState.hoveredElement!] : <FusionCanvasElement>[];

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
    DragToolState currentState,
  ) {
    final Offset delta = inputState.delta;

    if (currentState is LayerDragStartState) {
      return LayerDraggingState(layerId: currentState.layerId, delta: delta);
    } else if (currentState is LayerDraggingState) {
      return LayerDraggingState(
        layerId: currentState.layerId,
        delta: currentState.delta + delta,
      );
    }

    if (currentState is PointsDragStartState) {
      return PointsDraggingState(
        layerId: currentState.layerId,
        elements: currentState.elements,
        delta: delta,
      );
    } else if (currentState is PointsDraggingState) {
      return PointsDraggingState(
        layerId: currentState.layerId,
        elements: currentState.elements,
        delta: currentState.delta + delta,
      );
    }



    return currentState;
  }

  FusionToolState _handleDragEnd(
    FusionSnapState snapState,
    DragToolState currentState,
  ) {
    // Calculate snap adjustment if snapping is active
    final Offset snapAdjustment = _calculateSnapAdjustment(snapState);

    if (currentState is LayerDraggingState) {
      return LayerDragEndState(
        layerId: currentState.layerId,
        delta: currentState.delta + snapAdjustment,
      );
    } else if (currentState is PointsDraggingState) {
      return PointsDragEndState(
        layerId: currentState.layerId,
        elements: currentState.elements,
        delta: currentState.delta + snapAdjustment,
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
