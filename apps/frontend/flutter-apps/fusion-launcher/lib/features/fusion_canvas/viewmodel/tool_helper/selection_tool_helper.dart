import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/drag_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/select_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../state/fusion_canvas_input_state.dart';
import '../../state/tools/selection_tool_params.dart';
import '../../view/painters/elements/mixin/fusion_canvas_interactable_mixin.dart';
import '../fusion_canvas_tool_viewmodel.dart';
import '../tools/fusion_canvas_tool.dart';
import '../usecase/fc_interaction_resolver_usecase.dart';
import '../usecase/fc_layer_interaction_support_usecase.dart';
import '../usecase/fc_selectable_layers_in_rect_usecase.dart';

class SelectionToolHelper extends FusionCanvasToolTransformer<SelectToolState> {
  final SelectionToolParams selectionToolParams;
  const SelectionToolHelper({
    required this.selectionToolParams,
  });
  @override
  FusionToolState transform({
    required FusionCanvasInputState inputState,
    required FusionCanvasInputContext context,
    required SelectToolState currentState,
  }) {
    final bool selectionEnabled = selectionToolParams.enableSelect;

    if (inputState is FusionCanvasInputTapDownState) {
      return _handleTapDown(context, currentState);
    }

    if (inputState is FusionCanvasInputDraggingState) {
      return _handleDragging(inputState, context, currentState);
    }

    if (inputState is FusionCanvasInputTapUpState) {
      if (currentState is MarqueeSelectToolState && inputState.gestureOrigin == FusionGestureOrigin.drag && inputState.button == FusionMouseButton.left) {
        return IdleSelectToolState(
          selectedLayerIds: currentState.selectedLayerIds,
          selectedElementIds: <String>{},
        );
      }

      // Handle click gestures for selection
      if (selectionEnabled && inputState.gestureOrigin == FusionGestureOrigin.click && inputState.button == FusionMouseButton.left) {
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
    if (context.inputState is! FusionCanvasInputTapDownState) {
      return currentState;
    }

    final FusionCanvasInputTapDownState tapDownState = context.inputState as FusionCanvasInputTapDownState;
    if (tapDownState.button != FusionMouseButton.left) {
      return currentState;
    }

    final bool selectionEnabled = selectionToolParams.enableSelect;
    final bool multiSelectEnabled = selectionToolParams.enableMultiSelect;
    final bool marqueeSelectionEnabled = selectionToolParams.enableMarqueeSelection;

    final String? hoveredPainterId = context.hoverState.hoveredPainterId;

    if (hoveredPainterId != null && context.hoverState.supportsInteraction(FusionCanvasLayerInteraction.drag)) {
      // User tapped on an element - prepare for potential drag
      final List<FusionCanvasElement> elements =
          context.hoverState.hoveredElement != null ? <FusionCanvasElement>[context.hoverState.hoveredElement!] : <FusionCanvasElement>[];

      final Set<String> draggedLayerIds =
          (multiSelectEnabled && context.inputState.isShiftPressed) ? <String>{...currentState.selectedLayerIds, hoveredPainterId} : <String>{hoveredPainterId};
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
      // Tapped on empty canvas - start marquee selection.
      if (!selectionEnabled || !marqueeSelectionEnabled) {
        return currentState;
      }

      return MarqueeSelectToolState(
        startPosition: tapDownState.tapPosition,
        currentPosition: tapDownState.tapPosition,
        selectedLayerIds: currentState.selectedLayerIds,
        selectedElementIds: currentState.selectedElementIds,
      );
    }
  }

  FusionToolState _handleDragging(
    FusionCanvasInputDraggingState inputState,
    FusionCanvasInputContext context,
    SelectToolState currentState,
  ) {
    if (inputState.button != FusionMouseButton.left) {
      return currentState;
    }

    if (currentState is MarqueeSelectToolState) {
      final Rect selectionRect = Rect.fromPoints(
        currentState.startPosition,
        inputState.currentPosition,
      );
      final Set<String> boxSelectedLayerIds = FusionCanvasSelectableLayersInRectUseCase(
        painter: context.fusionCanvasPainter,
      ).call(selectionRect);
      final bool multiSelectEnabled = selectionToolParams.enableMultiSelect;
      final Set<String> effectiveSelectedLayerIds =
          (multiSelectEnabled && inputState.isShiftPressed) ? <String>{...currentState.selectedLayerIds, ...boxSelectedLayerIds} : boxSelectedLayerIds;

      return currentState.copyWith(
        currentPosition: inputState.currentPosition,
        selectedLayerIds: effectiveSelectedLayerIds,
        selectedElementIds: <String>{},
      );
    }

    final Offset delta = inputState.delta;

    // If we have selected layers, drag the first one
    if (currentState.selectedLayerIds.isNotEmpty) {
      final FusionCanvasInteractionTarget? dragTarget = FusionCanvasInteractionResolverUseCase(
        painter: context.fusionCanvasPainter,
      ).call(
        inputState.startPosition,
        FusionCanvasLayerInteraction.drag,
      );
      final String? dragTargetLayerId = dragTarget?.painter.id;
      if (dragTargetLayerId == null || !currentState.isLayerSelected(dragTargetLayerId)) {
        return currentState;
      }

      final Set<String> draggableLayerIds =
          currentState.selectedLayerIds
              .where(
                (String layerId) => FusionCanvasLayerInteractionSupportUseCase(
                  painter: context.fusionCanvasPainter,
                ).call(layerId, FusionCanvasLayerInteraction.drag),
              )
              .toSet();
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
    if (!selectionToolParams.enableSelect) {
      return currentState;
    }

    final bool multiSelectEnabled = selectionToolParams.enableMultiSelect;
    final String? hoveredPainterId = context.hoverState.hoveredPainterId;
    final String? hoveredElementId = context.hoverState.hoveredElement?.id;

    if (hoveredPainterId != null) {
      if (!context.hoverState.supportsInteraction(FusionCanvasLayerInteraction.select)) {
        return currentState;
      }
      final Set<String> effectiveSelectedLayerIds =
          (multiSelectEnabled && context.inputState.isShiftPressed)
              ? (currentState.selectedLayerIds.contains(hoveredPainterId)
                  ? (<String>{...currentState.selectedLayerIds}..remove(hoveredPainterId))
                  : (<String>{...currentState.selectedLayerIds}..add(hoveredPainterId)))
              : <String>{hoveredPainterId};

      final Set<String> effectiveSelectedElementIds =
          (multiSelectEnabled && context.inputState.isShiftPressed)
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
