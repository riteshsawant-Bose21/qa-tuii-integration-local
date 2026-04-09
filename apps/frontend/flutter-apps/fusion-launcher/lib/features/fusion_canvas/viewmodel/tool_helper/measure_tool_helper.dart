import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/measure_tool_state.dart';

import '../../state/fusion_canvas_input_state.dart';
import '../fusion_canvas_tool_viewmodel.dart';
import '../tools/fusion_canvas_tool.dart';

class MeasureToolHelper extends FusionCanvasToolTransformer<MeasureToolState> {
  const MeasureToolHelper();
  @override
  FusionToolState transform({
    required FusionCanvasInputState inputState,
    required FusionCanvasInputContext context,
    required MeasureToolState currentState,
  }) {
    if (inputState is FusionCanvasInputTapDownState) {
      if (inputState.button != FusionMouseButton.left) {
        return currentState;
      }
      final Offset position = context.snapState.effectivePosition ?? inputState.tapPosition;
      if (currentState is IdleMeasureToolState) {
        return DrawingMeasureToolState(start: position);
      } else if (currentState is DrawingMeasureToolState) {
        final DrawingMeasureToolState measureState = currentState;
        if (!measureState.isComplete) {
          return measureState.copyWith(end: position);
        } else {
          return DrawingMeasureToolState(start: position);
        }
      }
    }

    return currentState;
  }
}
