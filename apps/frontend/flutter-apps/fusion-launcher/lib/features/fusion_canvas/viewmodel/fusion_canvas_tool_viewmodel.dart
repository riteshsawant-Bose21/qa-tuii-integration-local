import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../state/fusion_tool_state.dart';
import '../state/tools/measure_tool_state.dart';
import 'fusion_canvas_input_viewmodel.dart';

class FusionCanvasToolViewModel extends Cubit<FusionToolState> {
  final FusionCanvasInputViewModel inputViewModel;
  FusionCanvasToolViewModel({required this.inputViewModel}) : super(FusionCanvasIdleToolState()) {
    inputViewModel.addListener(
      FusionInputEventsListener(
        onTapUp: onTapUp,
      ),
    );
  }

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
    }
  }

  void setTool(FusionToolState toolState) {
    emit(toolState);
  }
}
