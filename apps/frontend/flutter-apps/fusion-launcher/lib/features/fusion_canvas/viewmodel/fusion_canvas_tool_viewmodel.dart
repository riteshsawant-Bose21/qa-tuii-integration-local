import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/fusion_canvas_point.dart';
import '../state/fusion_tool_state.dart';
import '../state/tools/measure_tool_state.dart';
import '../state/tools/pen_tool_state.dart';
import 'fusion_canvas_input_viewmodel.dart';

class FusionCanvasToolViewModel extends Cubit<FusionToolState> {
  final FusionCanvasInputViewModel inputViewModel;
  FusionCanvasToolViewModel({required this.inputViewModel}) : super(FusionCanvasIdleToolState()) {
    inputViewModel.addListener(
      _listener,
    );
  }

  late final FusionInputEventsListener _listener = FusionInputEventsListener(
    onTapUp: onTapUp,
  );

  void onTapUp(Offset position) {
    if (state is MeasureToolState) {
      final MeasureToolState measureState = state as MeasureToolState;
      if (measureState.start == null) {
        setTool(measureState.copyWith(start: position));
      } else if (measureState.end == null) {
        setTool(measureState.copyWith(end: position));
      } else {
        setTool(MeasureToolState(start: position));
      }
    } else if (state is PenToolState) {
      final bool isCtrCmdPressed =
          inputViewModel.state.pressedKeys.contains(LogicalKeyboardKey.controlLeft) ||
          inputViewModel.state.pressedKeys.contains(LogicalKeyboardKey.controlRight);
      final PenToolState penState = state as PenToolState;
      setTool(
        DrawingPenToolState(
          points: <FusionCanvasPoint>[
            ...state is DrawingPenToolState ? (penState as DrawingPenToolState).points : <FusionCanvasPoint>[],
            FusionCanvasPoint(
              position: position,
              handleIn: isCtrCmdPressed ? position + const Offset(50, 50) : null,
              handleOut: isCtrCmdPressed ? position + const Offset(-50, -50) : null,
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
