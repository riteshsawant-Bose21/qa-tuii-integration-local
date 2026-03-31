import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_canvas_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';

import '../view/painters/fusion_canvas_painter.dart';

class FusionCanvasStateViewModel extends Cubit<FusionCanvasState> {
  FusionCanvasStateViewModel() : super(IdleFusionCanvasState(offset: Offset.zero, scale: 1.0));

  double get minScale => 0.05;
  double get maxScale => 2.0;

  Size? _canvasSize;

  Size? get canvasSize => _canvasSize;

  Size? _contentSize;

  Size? get contentSize => _contentSize;

  void updateContentSize(List<FusionBasePainter> painters, FusionCanvasPainter cPainter) {
    Rect contentRect = Rect.zero;
    for (final FusionBasePainter painter in painters) {
      final Rect bounds = painter.getBounds(cPainter);
      contentRect = contentRect.expandToInclude(bounds);
    }
    final bool isInitialZetting = _contentSize == null;

    _contentSize = contentRect.size;
    if (isInitialZetting) {
      fitToScreen();
    }
  }

  void setCanvasSize(Size size) {
    final bool isInitialZetting = _canvasSize == null;

    _canvasSize = size;
    if (isInitialZetting) {
      fitToScreen();
    }
  }

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

  void onStartPanZoom(Offset focalPoint) {
    _startScale = 1;
  }

  void onUpdatePanZoom(double scale, Offset focalPoint, Offset delta) {
    // print(" onUpdatePanZoom - scale: $scale, focalPoint: $focalPoint, delta: $delta");
    onScaleUpdate(scale, focalPoint);
    onPanUpdate(delta);
  }

  void onEndPanZoom() {
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

  void fitToScreen() {
    final Size? contSize = contentSize;
    Size? viewportSize = canvasSize;
    if (contSize == null || viewportSize == null) return;
    viewportSize = viewportSize * 0.6; // Add some padding around the content
    final double scaleX = viewportSize.width / contSize.width;
    final double scaleY = viewportSize.height / contSize.height;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    final Offset offset = Offset(contSize.width / 2, contSize.height / 2);
    print("Offset: $offset, Scale: $scale");
    setCanvasState(
      state
          .scaleCanvas(
            scale,
          )
          .recenter(offset, viewportSize),
    );
  }
}
