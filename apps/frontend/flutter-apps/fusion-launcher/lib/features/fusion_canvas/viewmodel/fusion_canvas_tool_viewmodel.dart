import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/fusion_canvas_point.dart';
import '../state/fusion_tool_state.dart';
import '../state/tools/measure_tool_state.dart';
import '../state/tools/pen_tool_state.dart';
import 'fusion_canvas_input_viewmodel.dart';
import 'fusion_snap_viewmodel.dart';

class FusionCanvasToolViewModel extends Cubit<FusionToolState> {
  final FusionCanvasInputViewModel inputViewModel;
  final FusionSnapViewModel snapViewModel;
  FusionCanvasToolViewModel({required this.inputViewModel, required this.snapViewModel}) : super(FusionCanvasIdleToolState()) {
    inputViewModel.addListener(
      _listener,
    );
  }

  late final FusionInputEventsListener _listener = FusionInputEventsListener(
    onTapUp: onTapUp,
  );

  void onTapUp(Offset position) {
    // Use effective position (snapped if available) instead of raw position
    final Offset effectivePosition = snapViewModel.state.effectivePosition ?? position;

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
      final bool isCtrCmdPressed = inputViewModel.isMetaPressed;
      final PenToolState penState = state as PenToolState;
      setTool(
        DrawingPenToolState(
          points: <FusionCanvasPoint>[
            ...state is DrawingPenToolState ? (penState as DrawingPenToolState).points : <FusionCanvasPoint>[],
            FusionCanvasPoint(
              position: effectivePosition,
              handleIn: isCtrCmdPressed ? effectivePosition + const Offset(50, 50) : null,
              handleOut: isCtrCmdPressed ? effectivePosition + const Offset(-50, -50) : null,
            ),
          ],
        ),
      );
    }
  }

  void setTool(FusionToolState toolState) {
    emit(toolState);
  }

  @override
  Future<void> close() {
    inputViewModel.removeListener(
      _listener,
    );
    return super.close();
  }
}
