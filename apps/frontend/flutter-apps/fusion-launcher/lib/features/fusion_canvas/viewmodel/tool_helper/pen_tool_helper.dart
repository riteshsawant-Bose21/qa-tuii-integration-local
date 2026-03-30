import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/pen_tool_state.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../state/fusion_canvas_input_state.dart';
import '../fusion_canvas_tool_viewmodel.dart';

class PenToolHelper {
  FusionToolState transform({
    required FusionCanvasInputState inputState,
    required FusionCanvasInputContext context,
    required PenToolState currentState,
  }) {
    if (inputState is FusionCanvasInputTapUpState) {
      // Only handle click gestures for pen tool (not drag ends)
      if (inputState.gestureOrigin == FusionGestureOrigin.click && inputState.button == FusionMouseButton.left) {
        final Offset position = context.snapState.effectivePosition ?? inputState.tapPosition;
        return currentState.addPoint(FusionCanvasPoint(position: position));
      }
    }

    if (inputState is FusionCanvasInputDoubleTapState) {
      // Double tap closes the path if we have at least 3 points
      if (currentState is DrawingPenToolState) {
        final DrawingPenToolState drawingState = currentState;
        if (drawingState.points.length >= 3) {
          return ClosedPenToolState(points: drawingState.points);
        }
      }
    }

    if (inputState is FusionCanvasInputSecondaryTapState) {
      // Right-click cancels pen tool and resets to idle
      return IdlePenToolState();
    }

    return currentState;
  }
}
