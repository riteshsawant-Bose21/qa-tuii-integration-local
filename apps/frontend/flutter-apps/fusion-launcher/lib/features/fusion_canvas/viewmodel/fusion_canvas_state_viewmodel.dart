import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_canvas_state.dart';

class FusionCanvasStateViewModel extends Cubit<FusionCanvasState> {
  FusionCanvasStateViewModel() : super(IdleFusionCanvasState(offset: Offset.zero, scale: 1.0));

  double get minScale => 0.25;
  double get maxScale => 2.0;

  Size? canvasSize;
  bool isWithinViewport(Offset position) {
    final Rect rect = (state.offset & ((canvasSize ?? const Size(100, 100)) * state.scale));
    final bool contains = rect.contains(
      position,
    );
    return contains;
  }

  void recenter(Offset center) {
    setCanvasState(
      state.recenter(
        center,
        ((canvasSize ?? const Size(100, 100))),
      ),
    );
  }

  void onPanStart(DragStartDetails details) {
    // Handle pan start if needed
  }

  void onPanUpdate(Offset delta) {
    setCanvasState(state.pan(delta * (state.scale)));
  }

  void onPanEnd(DragEndDetails details) {
    setCanvasState(state.idle());
  }

  double? _startScale;
  void onScaleStart(ScaleStartDetails details) {
    // Handle scale start if needed
    _startScale = 1;
  }

  void onScaleUpdate(double scale, Offset focalPoint) {
    final double diffScale = _startScale != null ? scale - _startScale! : scale;
    if (_startScale != null) {
      _startScale = scale;
    }
    final double oldScale = state.scale;
    final double newScale = (state.scale + diffScale).clamp(
      minScale,
      maxScale,
    );

    // Calculate the actual scale change that will be applied
    final double actualScaleChange = newScale / oldScale;

    // Adjust offset to zoom towards focal point
    // The focal point should remain at the same screen position
    final Offset delta = (focalPoint - (focalPoint - state.offset) * actualScaleChange) - state.offset;
    setCanvasState(state.scaleCanvas(newScale, offset: delta));
  }

  void onScaleEnd(ScaleEndDetails details) {
    // Handle scale end if needed
    setCanvasState(state.idle());
    _startScale = null;
  }

  void setCanvasState(FusionCanvasState state) {
    emit(state);
  }

  Offset correctPosition(Offset position) {
    final Offset offset = state.offset;
    final double scale = state.scale;
    return (position - offset) / scale;
  }

  Offset transformPosition(Offset position) {
    final Offset offset = state.offset;
    final double scale = state.scale;
    return (position * scale) + offset;
  }
}
