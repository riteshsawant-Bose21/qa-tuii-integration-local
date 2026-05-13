import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/rectangle_tool_state.dart';

import '../../state/fusion_canvas_input_state.dart';
import '../fusion_canvas_tool_viewmodel.dart';
import '../tools/fusion_canvas_tool.dart';

class RectangleToolHelper extends FusionCanvasToolTransformer<RectangleToolState> {
  const RectangleToolHelper();

  @override
  FusionToolState transform({
    required FusionCanvasInputState inputState,
    required FusionCanvasInputContext context,
    required RectangleToolState currentState,
  }) {
    if (inputState is FusionCanvasInputTapDownState && inputState.button == FusionMouseButton.left) {
      final Offset start = context.snapState.effectivePosition ?? inputState.tapPosition;
      return DrawingRectangleToolState(start: start, current: start);
    }

    if (inputState is FusionCanvasInputDraggingState && inputState.button == FusionMouseButton.left && currentState is DrawingRectangleToolState) {
      final Offset current = context.snapState.effectivePosition ?? inputState.currentPosition;
      return DrawingRectangleToolState(start: currentState.start, current: current);
    }

    if (inputState is FusionCanvasInputTapUpState && inputState.button == FusionMouseButton.left && currentState is DrawingRectangleToolState) {
      final Offset end = context.snapState.effectivePosition ?? inputState.tapPosition;
      final DrawingRectangleToolState finalDrawingState = DrawingRectangleToolState(start: currentState.start, current: end);
      if (_isValidRect(finalDrawingState.rect)) {
        return DrawnRectangleToolState(points: finalDrawingState.points);
      }
      return CancelledRectangleToolState(points: finalDrawingState.points);
    }

    if (inputState is FusionCanvasInputSecondaryTapState) {
      if (currentState is DrawingRectangleToolState) {
        return CancelledRectangleToolState(points: currentState.points);
      }
      return IdleRectangleToolState();
    }

    if (inputState.isEscPressed) {
      if (currentState is DrawingRectangleToolState) {
        return CancelledRectangleToolState(points: currentState.points);
      }
      return IdleRectangleToolState();
    }

    return currentState;
  }

  bool _isValidRect(Rect rect) {
    const double minSize = 1;
    return rect.width.abs() >= minSize && rect.height.abs() >= minSize;
  }
}
