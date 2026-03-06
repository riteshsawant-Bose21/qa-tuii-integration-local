import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_hover_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/drag_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/select_tool_state.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../state/fusion_canvas_input_state.dart';
import '../state/fusion_snap_state.dart';
import '../state/fusion_tool_state.dart';
import '../state/tools/measure_tool_state.dart';
import '../state/tools/pen_tool_state.dart';

/// Context containing all information needed for input state handling
class FusionCanvasInputContext {
  final FusionHoverState hoverState;
  final FusionSnapState snapState;

  const FusionCanvasInputContext({
    required this.hoverState,
    required this.snapState,
  });
}

class FusionCanvasToolViewModel extends Cubit<FusionToolState> {
  FusionCanvasToolViewModel() : super(FusionCanvasIdleToolState());

  // ==================== Drag Operations ====================

  void startLayerDrag(String layerId) {
    emit(LayerDragStartState(layerId: layerId));
  }

  void startPointsDrag(String layerId, List<FusionCanvasElement> pointIds) {
    emit(PointsDragStartState(layerId: layerId, elements: pointIds));
  }

  void updateDragDelta(Offset delta) {
    final FusionToolState currentState = state;
    if (currentState is LayerDragStartState) {
      emit(LayerDraggingState(layerId: currentState.layerId, delta: delta));
    } else if (currentState is LayerDraggingState) {
      emit(LayerDraggingState(layerId: currentState.layerId, delta: currentState.delta + delta));
    }
    if (currentState is PointsDragStartState) {
      emit(PointsDraggingState(layerId: currentState.layerId, elements: currentState.elements, delta: delta));
    } else if (currentState is PointsDraggingState) {
      emit(PointsDraggingState(layerId: currentState.layerId, elements: currentState.elements, delta: currentState.delta + delta));
    }
    if (currentState is IdleSelectToolState) {
      if (currentState.selectedLayerIds.isNotEmpty) {
        emit(LayerDraggingState(layerId: currentState.selectedLayerIds.first, delta: delta));
      } else {
        emit(CanvasPanningState(delta: delta));
      }
    }
    if (currentState is CanvasPanningState) {
      emit(CanvasPanningState(delta: delta));
    }
  }

  void setCanvasPanning(Offset delta) {
    emit(CanvasPanningState(delta: delta));
  }

  void onDragEnd({FusionSnapState? snapState}) {
    final FusionToolState currentState = state;

    // Calculate snap adjustment if snapping is active
    Offset snapAdjustment = Offset.zero;
    if (snapState != null && snapState.isSnapped && snapState.cursorPositions != null && snapState.snapResult?.cursorIndex != null) {
      final int cursorIndex = snapState.snapResult!.cursorIndex!;
      if (cursorIndex < snapState.cursorPositions!.length) {
        final Offset currentPosition = snapState.cursorPositions![cursorIndex];
        final Offset snappedPosition = snapState.snapResult!.snappedPosition;
        snapAdjustment = snappedPosition - currentPosition;
      }
    }

    if (currentState is LayerDraggingState) {
      emit(LayerDragEndState(layerId: currentState.layerId, delta: currentState.delta + snapAdjustment));
    } else if (currentState is PointsDraggingState) {
      emit(PointsDragEndState(layerId: currentState.layerId, elements: currentState.elements, delta: currentState.delta + snapAdjustment));
    } else {
      setIdle();
    }
  }

  void setIdle() {
    emit(FusionCanvasIdleToolState());
  }

  // ==================== Input State Handling ====================

  /// Main entry point for processing all canvas input events.
  /// Returns true if the event was handled by the tool viewmodel.
  bool onInputStateChanged(
    FusionCanvasInputState inputState,
    FusionCanvasInputContext context,
  ) {
    return switch (inputState) {
      FusionCanvasInputTapDownState() => _handleTapDown(inputState, context),
      FusionCanvasInputDraggingState() => _handleDragging(inputState, context),
      FusionCanvasInputTapUpState() => _handleTapUp(inputState, context),
      FusionCanvasInputDoubleTapState() => _handleDoubleTap(inputState, context),
      FusionCanvasInputLongPressState() => _handleLongPress(inputState, context),
      FusionCanvasInputSecondaryTapState() => _handleSecondaryTap(inputState, context),
      _ => false,
    };
  }

  // ==================== Use Cases ====================

  /// Handle tap down - initiates drag operations based on hover state
  bool _handleTapDown(
    FusionCanvasInputTapDownState inputState,
    FusionCanvasInputContext context,
  ) {
    // Skip drag handling for measure and pen tools
    if (state is MeasureToolState || state is PenToolState) {
      return false;
    }

    final FusionHoverState hoverState = context.hoverState;

    if (hoverState.hoveredPainterId != null) {
      // User tapped on an element - determine if it's points or layer drag
      final List<FusionCanvasElement> pointIds =
          hoverState.hoveredElement != null ? <FusionCanvasElement>[hoverState.hoveredElement!] : <FusionCanvasElement>[];
      print("Hovered element: ${hoverState.hoveredElement}, extracted point IDs: ${pointIds.map((FusionCanvasElement e) => e.id).toList()}");
      if (pointIds.isNotEmpty) {
        startPointsDrag(hoverState.hoveredPainterId!, pointIds);
      } else {
        startLayerDrag(hoverState.hoveredPainterId!);
      }
    } else {
      // User tapped on empty canvas - start panning
      setCanvasPanning(Offset.zero);
    }

    return true;
  }

  /// Handle dragging - updates drag delta
  bool _handleDragging(
    FusionCanvasInputDraggingState inputState,
    FusionCanvasInputContext context,
  ) {
    updateDragDelta(inputState.delta);
    return true;
  }

  /// Handle tap up - completes drag or handles tool-specific click actions
  bool _handleTapUp(
    FusionCanvasInputTapUpState inputState,
    FusionCanvasInputContext context,
  ) {
    if (inputState.gestureOrigin == FusionGestureOrigin.drag) {
      // Drag gesture ended - complete the drag operation with snap adjustment
      onDragEnd(snapState: context.snapState);
      return true;
    }

    if (inputState.gestureOrigin == FusionGestureOrigin.click && inputState.button == FusionMouseButton.left) {
      // Handle tool-specific click actions
      return _handleToolClick(
        context.snapState.effectivePosition ?? inputState.tapPosition,
        context,
      );
    }

    return false;
  }

  /// Handle double tap - used for closing pen tool paths
  bool _handleDoubleTap(
    FusionCanvasInputDoubleTapState inputState,
    FusionCanvasInputContext context,
  ) {
    if (state is DrawingPenToolState) {
      final DrawingPenToolState penState = state as DrawingPenToolState;
      if (penState.points.length >= 3) {
        setTool(ClosedPenToolState(points: penState.points));
        return true;
      }
    }
    return false;
  }

  /// Handle long press - can be extended for context menus etc.
  bool _handleLongPress(
    FusionCanvasInputLongPressState inputState,
    FusionCanvasInputContext context,
  ) {
    return false;
  }

  /// Handle secondary tap (right-click) - cancels current tool
  bool _handleSecondaryTap(
    FusionCanvasInputSecondaryTapState inputState,
    FusionCanvasInputContext context,
  ) {
    if (state is DrawingMeasureToolState || state is DrawingPenToolState) {
      setTool(FusionCanvasIdleToolState());
      return true;
    }
    return false;
  }

  // ==================== Tool Click Handlers ====================

  /// Handle click actions for different tools (measure, pen)
  bool _handleToolClick(Offset effectivePosition, FusionCanvasInputContext context) {
    if (state is MeasureToolState) {
      return _handleMeasureToolClick(effectivePosition);
    } else if (state is PenToolState) {
      return _handlePenToolClick(effectivePosition);
    } else if (context.hoverState.hoveredPainterId != null) {
      final String? id2 = context.hoverState.hoveredElement?.id;
      emit(
        IdleSelectToolState(
          selectedLayerIds: <String>{context.hoverState.hoveredPainterId!},
          selectedElementIds: id2 != null ? <String>{id2} : <String>{},
        ),
      );
      return true;
    }
    return false;
  }

  bool _handleMeasureToolClick(Offset position) {
    if (state is IdleMeasureToolState) {
      setTool(DrawingMeasureToolState(start: position));
      return true;
    } else if (state is DrawingMeasureToolState) {
      final DrawingMeasureToolState measureState = state as DrawingMeasureToolState;
      if (!measureState.isComplete) {
        setTool(measureState.copyWith(end: position));
      } else {
        setTool(DrawingMeasureToolState(start: position));
      }
      return true;
    }
    return false;
  }

  bool _handlePenToolClick(Offset position) {
    final PenToolState penState = state as PenToolState;
    setTool(penState.addPoint(FusionCanvasPoint(position: position)));
    return true;
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

  /// Select a single layer (replaces current selection)
  // void selectLayer(String layerId) {
  //   emit(IdleSelectToolState(selectedLayerIds: <String>{layerId}));
  // }

  /// Update selection from external source (sync with provided IDs)
  void syncSelection(Set<String> layerIds) {
    emit(IdleSelectToolState(selectedLayerIds: layerIds));
  }
}
