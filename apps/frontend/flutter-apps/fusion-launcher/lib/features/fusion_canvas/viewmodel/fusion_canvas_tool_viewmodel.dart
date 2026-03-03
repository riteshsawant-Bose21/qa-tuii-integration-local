import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/select_tool_state.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../state/fusion_canvas_input_state.dart';
import '../state/fusion_snap_state.dart';
import '../state/fusion_tool_state.dart';
import '../state/tools/measure_tool_state.dart';
import '../state/tools/pen_tool_state.dart';

class FusionCanvasToolViewModel extends Cubit<FusionToolState> {
  FusionCanvasToolViewModel() : super(FusionCanvasIdleToolState());
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
    } else {
      setTool(IdleSelectToolState());
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
}
