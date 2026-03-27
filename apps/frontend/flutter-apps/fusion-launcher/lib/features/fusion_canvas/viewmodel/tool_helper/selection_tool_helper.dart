import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/drag_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/select_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../state/fusion_canvas_input_state.dart';
import '../../view/painters/elements/mixin/fusion_canvas_interactable_mixin.dart';
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

    if (hoveredPainterId != null && context.hoverState.supportsInteraction(FusionCanvasLayerInteraction.drag)) {
      // User tapped on an element - prepare for potential drag
      final List<FusionCanvasElement> elements =
          context.hoverState.hoveredElement != null ? <FusionCanvasElement>[context.hoverState.hoveredElement!] : <FusionCanvasElement>[];

      final Set<String> draggedLayerIds =
          context.inputState.isShiftPressed ? <String>{...currentState.selectedLayerIds, hoveredPainterId} : <String>{hoveredPainterId};
      if (elements.isNotEmpty) {
        final Set<String> draggableLayerIds =
            draggedLayerIds
                .where(
                  (String layerId) => layerId == hoveredPainterId || context.supportsLayerInteraction(layerId, FusionCanvasLayerInteraction.drag),
                )
                .toSet();
        if (draggableLayerIds.isEmpty) {
          return currentState;
        }
        return PointsDragStartState(layerIds: draggableLayerIds, elements: elements);
      } else {
        final Set<String> draggableLayerIds =
            draggedLayerIds.where((String layerId) => context.supportsLayerInteraction(layerId, FusionCanvasLayerInteraction.drag)).toSet();
        if (draggableLayerIds.isEmpty) {
          return currentState;
        }
        return LayerDragStartState(layerIds: draggableLayerIds);
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
      final FusionCanvasInteractionTarget? dragTarget = context.resolveInteractionTargetAt(
        inputState.startPosition,
        FusionCanvasLayerInteraction.drag,
      );
      final String? dragTargetLayerId = dragTarget?.painter.id;
      if (dragTargetLayerId == null || !currentState.isLayerSelected(dragTargetLayerId)) {
        return currentState;
      }

      final Set<String> draggableLayerIds =
          currentState.selectedLayerIds.where((String layerId) => context.supportsLayerInteraction(layerId, FusionCanvasLayerInteraction.drag)).toSet();
      if (draggableLayerIds.isEmpty) {
        return currentState;
      }

      return LayerDraggingState(layerIds: draggableLayerIds, delta: delta);
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
      if (!context.hoverState.supportsInteraction(FusionCanvasLayerInteraction.select)) {
        return currentState;
      }
      final Set<String> effectiveSelectedLayerIds =
          context.inputState.isShiftPressed
              ? (currentState.selectedLayerIds.contains(hoveredPainterId)
                  ? (<String>{...currentState.selectedLayerIds}..remove(hoveredPainterId))
                  : (<String>{...currentState.selectedLayerIds}..add(hoveredPainterId)))
              : <String>{hoveredPainterId};

      final Set<String> effectiveSelectedElementIds =
          context.inputState.isShiftPressed
              ? (currentState.selectedElementIds.contains(hoveredElementId)
                  ? (<String>{...currentState.selectedElementIds}..remove(hoveredElementId))
                  : hoveredElementId != null
                  ? (<String>{...currentState.selectedElementIds}..add(hoveredElementId))
                  : <String>{...currentState.selectedElementIds})
              : (hoveredElementId != null ? <String>{hoveredElementId} : <String>{});

      // Clicked on a layer - select it
      return IdleSelectToolState(
        selectedLayerIds: effectiveSelectedLayerIds,
        selectedElementIds: effectiveSelectedElementIds,
      );
    } else {
      // Clicked on empty canvas - clear selection
      return IdleSelectToolState();
    }
  }
}
