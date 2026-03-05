import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../state/fusion_action_state.dart';

class FusionCanvasActionViewModel extends Cubit<FusionActionState> {
  FusionCanvasActionViewModel() : super(FusionToolActiveState());

  void setToolActive() {
    emit(FusionToolActiveState());
  }

  void startLayerDrag(String layerId) {
    emit(FusionLayerDragStartState(layerId: layerId));
  }

  void updateDragDelta(Offset delta) {
    final FusionActionState currentState = state;
    if (currentState is FusionLayerDragStartState) {
      emit(FusionLayerDraggingState(layerId: currentState.layerId, delta: delta));
    } else if (currentState is FusionLayerDraggingState) {
      emit(FusionLayerDraggingState(layerId: currentState.layerId, delta: currentState.delta + delta));
    }
    if (currentState is FusionPointsDragStartState) {
      emit(FusionPointsDraggingState(layerId: currentState.layerId, pointId: currentState.pointId, delta: delta));
    } else if (currentState is FusionPointsDraggingState) {
      emit(FusionPointsDraggingState(layerId: currentState.layerId, pointId: currentState.pointId, delta: currentState.delta + delta));
    }
    if (currentState is FusionCanvasPanningState) {
      emit(FusionCanvasPanningState(delta: delta));
    }
  }

  void startPointsDrag(String layerId, List<String> pointIds) {
    emit(FusionPointsDragStartState(layerId: layerId, pointId: pointIds));
  }

  void setCanvasPanning(Offset delta) {
    emit(
      FusionCanvasPanningState(
        delta: delta,
      ),
    );
  }

  void onDragEnd() {
    final FusionActionState currentState = state;
    if (currentState is FusionLayerDraggingState) {
      emit(FusionLayerDragEndState(layerId: currentState.layerId, delta: currentState.delta));
    } else if (currentState is FusionPointsDraggingState) {
      emit(FusionPointsDragEndState(layerId: currentState.layerId, pointId: currentState.pointId, delta: currentState.delta));
    } else {
      setToolActive();
    }
  }
}
