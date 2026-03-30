import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/drag_tool_state.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../state/fusion_canvas_input_state.dart';
import '../../state/fusion_snap_state.dart';
import '../../state/tools/select_tool_state.dart';
import '../../view/painters/elements/mixin/fusion_canvas_interactable_mixin.dart';
import '../fusion_canvas_tool_viewmodel.dart';
import '../tools/fusion_canvas_tool.dart';
import '../usecase/fc_bounded_delta_resolver_usecase.dart';
import '../usecase/fc_layer_interaction_support_usecase.dart';

class DragToolHelper extends FusionCanvasToolTransformer<DragToolState> {
  const DragToolHelper();
  @override
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
          final Set<String> selectedLayerIds = <String>{...currentState.selectedLayerIds};
          // final Set<String> selectedElementIds = <String>{...currentState.selectedElementIds};

          final bool isShiftPressed = context.inputState.isShiftPressed;
          final Set<String> effectiveSelectedLayerIds = isShiftPressed ? (<String>{...selectedLayerIds, hoveredPainterId}) : <String>{hoveredPainterId};

          final Set<String> effectiveSelectedElementIds =
              isShiftPressed
                  ? (hoveredElementId != null
                      ? (<String>{...currentState.selectedElementIds}..add(hoveredElementId))
                      : <String>{...currentState.selectedElementIds})
                  : (hoveredElementId != null ? <String>{hoveredElementId} : <String>{});
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

      final Set<String> draggedLayerIds =
          context.inputState.isShiftPressed ? <String>{...currentState.selectedLayerIds, hoveredPainterId} : <String>{hoveredPainterId};
      if (elements.isNotEmpty) {
        final Set<String> draggableLayerIds =
            draggedLayerIds.where(
              (String layerId) {
                final bool supportsDrag = FusionCanvasLayerInteractionSupportUseCase(
                  painter: context.fusionCanvasPainter,
                ).call(layerId, FusionCanvasLayerInteraction.drag);
                return layerId == hoveredPainterId || supportsDrag;
              },
            ).toSet();
        if (draggableLayerIds.isEmpty) {
          return currentState;
        }
        return PointsDragStartState(layerIds: draggableLayerIds, elements: elements);
      } else {
        final Set<String> draggableLayerIds =
            draggedLayerIds
                .where(
                  (String layerId) => FusionCanvasLayerInteractionSupportUseCase(
                    painter: context.fusionCanvasPainter,
                  ).call(layerId, FusionCanvasLayerInteraction.drag),
                )
                .toSet();
        if (draggableLayerIds.isEmpty) {
          return currentState;
        }
        return LayerDragStartState(layerIds: draggableLayerIds);
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
      final Offset boundedDelta = _resolveBoundedDeltaForLayers(
        context: context,
        layerIds: currentState.layerIds,
        proposedDelta: delta,
      );
      return LayerDraggingState(layerIds: currentState.layerIds, delta: boundedDelta);
    } else if (currentState is LayerDraggingState) {
      final Offset boundedDelta = _resolveBoundedDeltaForLayers(
        context: context,
        layerIds: currentState.layerIds,
        proposedDelta: currentState.delta + delta,
      );
      return LayerDraggingState(
        layerIds: currentState.layerIds,
        delta: boundedDelta,
      );
    }

    if (currentState is PointsDragStartState) {
      final Offset boundedDelta = _resolveBoundedDeltaForLayers(
        context: context,
        layerIds: currentState.layerIds,
        proposedDelta: delta,
      );
      return PointsDraggingState(
        layerIds: currentState.layerIds,
        elements: currentState.elements,
        delta: boundedDelta,
      );
    } else if (currentState is PointsDraggingState) {
      final Offset boundedDelta = _resolveBoundedDeltaForLayers(
        context: context,
        layerIds: currentState.layerIds,
        proposedDelta: currentState.delta + delta,
      );
      return PointsDraggingState(
        layerIds: currentState.layerIds,
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
      final Offset boundedDelta = _resolveBoundedDeltaForLayers(
        context: context,
        layerIds: currentState.layerIds,
        proposedDelta: currentState.delta + snapAdjustment,
      );
      return LayerDragEndState(
        layerIds: currentState.layerIds,
        delta: boundedDelta,
      );
    } else if (currentState is PointsDraggingState) {
      final Offset boundedDelta = _resolveBoundedDeltaForLayers(
        context: context,
        layerIds: currentState.layerIds,
        proposedDelta: currentState.delta + snapAdjustment,
      );
      return PointsDragEndState(
        layerIds: currentState.layerIds,
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

  Offset _resolveBoundedDeltaForLayers({
    required FusionCanvasInputContext context,
    required Set<String> layerIds,
    required Offset proposedDelta,
  }) {
    if (layerIds.isEmpty) {
      return proposedDelta;
    }

    double boundedDx = proposedDelta.dx;
    double boundedDy = proposedDelta.dy;

    for (final String layerId in layerIds) {
      final Offset boundedForLayer = FusionCanvasBoundedDeltaResolverUseCase(
        painter: context.fusionCanvasPainter,
      ).call(layerId, proposedDelta);

      if (proposedDelta.dx >= 0) {
        boundedDx = boundedForLayer.dx < boundedDx ? boundedForLayer.dx : boundedDx;
      } else {
        boundedDx = boundedForLayer.dx > boundedDx ? boundedForLayer.dx : boundedDx;
      }

      if (proposedDelta.dy >= 0) {
        boundedDy = boundedForLayer.dy < boundedDy ? boundedForLayer.dy : boundedDy;
      } else {
        boundedDy = boundedForLayer.dy > boundedDy ? boundedForLayer.dy : boundedDy;
      }
    }

    return Offset(boundedDx, boundedDy);
  }
}
