import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/drag_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/select_tool_state.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../state/fusion_canvas_input_state.dart';
import '../state/fusion_snap_state.dart';
import '../state/fusion_tool_state.dart';
import '../state/tools/measure_tool_state.dart';
import '../state/tools/pen_tool_state.dart';

class FusionCanvasToolViewModel extends Cubit<FusionToolState> {
  FusionCanvasToolViewModel() : super(FusionCanvasIdleToolState());

  // ==================== Drag Operations ====================

  void startLayerDrag(String layerId) {
    print(" Start Drag Layer: $layerId, ");

    emit(LayerDragStartState(layerId: layerId));
  }

  void startPointsDrag(String layerId, List<String> pointIds) {
    print(" Start Drag Points: $layerId, $pointIds");
    emit(PointsDragStartState(layerId: layerId, pointIds: pointIds));
  }

  void updateDragDelta(Offset delta) {
    print("On Drag Update: $delta.  $state");
    final FusionToolState currentState = state;
    if (currentState is LayerDragStartState) {
      emit(LayerDraggingState(layerId: currentState.layerId, delta: delta));
    } else if (currentState is LayerDraggingState) {
      emit(LayerDraggingState(layerId: currentState.layerId, delta: currentState.delta + delta));
    }
    if (currentState is PointsDragStartState) {
      emit(PointsDraggingState(layerId: currentState.layerId, pointIds: currentState.pointIds, delta: delta));
    } else if (currentState is PointsDraggingState) {
      emit(PointsDraggingState(layerId: currentState.layerId, pointIds: currentState.pointIds, delta: currentState.delta + delta));
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

  void onDragEnd() {
    final FusionToolState currentState = state;
    if (currentState is LayerDraggingState) {
      emit(LayerDragEndState(layerId: currentState.layerId, delta: currentState.delta));
    } else if (currentState is PointsDraggingState) {
      emit(PointsDragEndState(layerId: currentState.layerId, pointIds: currentState.pointIds, delta: currentState.delta));
    } else {
      setIdle();
    }
  }

  void setIdle() {
    emit(FusionCanvasIdleToolState());
  }

  // ==================== Input State Handling ====================
  bool onInputStateChanged(
    FusionCanvasInputState inputState,
    FusionSnapState snapResult,
  ) {
    switch (inputState) {
      case FusionCanvasInputTapUpState(:final Offset tapPosition, :final FusionMouseButton button, :final FusionGestureOrigin gestureOrigin):
        if (button == FusionMouseButton.left && gestureOrigin == FusionGestureOrigin.click) {
          return _onTapUp(snapResult.effectivePosition ?? tapPosition);
        }
      case FusionCanvasInputDoubleTapState(:final Offset tapPosition):
        return _onDoubleTap(tapPosition);
      case FusionCanvasInputLongPressState(:final Offset pressPosition):
        return _onLongPress(pressPosition);
      case FusionCanvasInputSecondaryTapState(:final Offset tapPosition):
        return _onSecondaryTap(tapPosition);
      case _:
        // No action needed for idle state
        break;
    }
    return false;
  }

  bool _onTapUp(Offset position) {
    // Use effective position (snapped if available) instead of raw position
    final Offset effectivePosition = position;

    if (state is MeasureToolState) {
      if (state is IdleMeasureToolState) {
        // Start new measurement
        setTool(DrawingMeasureToolState(start: effectivePosition));
        return true; // Indicate that the event was handled
      } else if (state is DrawingMeasureToolState) {
        final DrawingMeasureToolState measureState = state as DrawingMeasureToolState;
        if (!measureState.isComplete) {
          // Complete the measurement
          setTool(measureState.copyWith(end: effectivePosition));
          return true; // Indicate that the event was handled
        } else {
          // Start new measurement
          setTool(DrawingMeasureToolState(start: effectivePosition));
        }
        return true; // Indicate that the event was handled
      }
    } else if (state is PenToolState) {
      final PenToolState penState = state as PenToolState;
      setTool(
        penState.addPoint(FusionCanvasPoint(position: effectivePosition)),
      );
      return true; // Indicate that the event was handled
    }
    return false;
  }

  bool _onDoubleTap(Offset position) {
    // Handle double tap events - can be extended based on tool requirements
    // Example: Close pen tool path on double tap
    if (state is DrawingPenToolState) {
      final DrawingPenToolState penState = state as DrawingPenToolState;
      if (penState.points.length >= 3) {
        setTool(ClosedPenToolState(points: penState.points));
        return true; // Indicate that the event was handled
      }
    }
    return false;
  }

  bool _onLongPress(Offset position) {
    return false; // Indicate that the event was not handled
    // Handle long press events - can be extended based on tool requirements
  }

  bool _onSecondaryTap(Offset position) {
    if (state is DrawingMeasureToolState || state is DrawingPenToolState) {
      setTool(FusionCanvasIdleToolState());
      return true; // Indicate that the event was handled
    }
    return false; // Indicate that the event was not handled
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

  /// Check if a layer is selected
  bool isLayerSelected(String? layerId) {
    if (layerId == null) return false;
    return selectedLayerIds.contains(layerId);
  }

  /// Select a single layer (replaces current selection)
  void selectLayer(String layerId) {
    print("Selecting layer: $layerId");
    emit(IdleSelectToolState(selectedLayerIds: <String>{layerId}));
  }

  /// Add a layer to selection
  void addToSelection(String layerId) {
    print("Adding to selection: $layerId");
    final Set<String> newSelection = Set<String>.from(selectedLayerIds)..add(layerId);
    emit(IdleSelectToolState(selectedLayerIds: newSelection));
  }

  /// Remove a layer from selection
  void removeFromSelection(String layerId) {
    print("Removing from selection: $layerId");
    final Set<String> newSelection = Set<String>.from(selectedLayerIds)..remove(layerId);
    emit(IdleSelectToolState(selectedLayerIds: newSelection));
  }

  /// Toggle layer selection
  void toggleSelection(String layerId) {
    if (isLayerSelected(layerId)) {
      removeFromSelection(layerId);
    } else {
      addToSelection(layerId);
    }
  }

  /// Clear all selections
  void clearSelection() {
    print("Clearing all selections");
    emit(IdleSelectToolState());
  }

  /// Update selection from external source (sync with provided IDs)
  void syncSelection(Set<String> layerIds) {
    print("Syncing selection with external IDs: $layerIds");
    emit(IdleSelectToolState(selectedLayerIds: layerIds));
  }
}
