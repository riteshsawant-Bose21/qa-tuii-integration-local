import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../state/fusion_canvas_input_state.dart';
import '../state/fusion_snap_state.dart';
import '../state/fusion_tool_state.dart';
import '../state/tools/measure_tool_state.dart';
import '../state/tools/pen_tool_state.dart';

class FusionCanvasToolViewModel extends Cubit<FusionToolState> {
  FusionCanvasToolViewModel() : super(FusionCanvasIdleToolState());
  void onInputStateChanged(FusionCanvasInputState inputState, FusionSnapState snapResult) {
    switch (inputState) {
      case FusionCanvasInputTapUpState(:final Offset tapPosition, :final FusionMouseButton button, :final FusionGestureOrigin gestureOrigin):
        if (button == FusionMouseButton.left && gestureOrigin == FusionGestureOrigin.click) {
          _onTapUp(snapResult.effectivePosition ?? tapPosition);
        }
      case FusionCanvasInputDoubleTapState(:final Offset tapPosition):
        _onDoubleTap(tapPosition);
      case FusionCanvasInputLongPressState(:final Offset pressPosition):
        _onLongPress(pressPosition);
      case FusionCanvasInputSecondaryTapState(:final Offset tapPosition):
        _onSecondaryTap(tapPosition);
      case _:
        // No action needed for idle state
        break;
    }
  }

  void _onTapUp(Offset position) {
    // Use effective position (snapped if available) instead of raw position
    final Offset effectivePosition = position;

    if (state is MeasureToolState) {
      if (state is IdleMeasureToolState) {
        // Start new measurement
        setTool(DrawingMeasureToolState(start: effectivePosition));
      } else if (state is DrawingMeasureToolState) {
        final DrawingMeasureToolState measureState = state as DrawingMeasureToolState;
        if (!measureState.isComplete) {
          // Complete the measurement
          setTool(measureState.copyWith(end: effectivePosition));
        } else {
          // Start new measurement
          setTool(DrawingMeasureToolState(start: effectivePosition));
        }
      }
    } else if (state is PenToolState) {
      final PenToolState penState = state as PenToolState;
      setTool(
        penState.addPoint(FusionCanvasPoint(position: effectivePosition)),
      );
    }
  }

  void _onDoubleTap(Offset position) {
    // Handle double tap events - can be extended based on tool requirements
    // Example: Close pen tool path on double tap
    if (state is DrawingPenToolState) {
      final DrawingPenToolState penState = state as DrawingPenToolState;
      if (penState.points.length >= 3) {
        setTool(ClosedPenToolState(points: penState.points));
      }
    }
  }

  void _onLongPress(Offset position) {
    // Handle long press events - can be extended based on tool requirements
  }

  void _onSecondaryTap(Offset position) {
    if (state is DrawingMeasureToolState || state is DrawingPenToolState) {
      setTool(FusionCanvasIdleToolState());
    }
  }

  void setTool(FusionToolState toolState) {
    emit(toolState);
  }
}
