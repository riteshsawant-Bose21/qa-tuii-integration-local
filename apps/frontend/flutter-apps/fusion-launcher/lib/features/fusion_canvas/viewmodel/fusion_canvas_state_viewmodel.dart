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

  Size? get contentSize => contentRect?.size;
  Rect? contentRect;
  void updateContentSize(List<FusionBasePainter> painters, FusionCanvasPainter cPainter) {
    Rect contentRect = Rect.zero;
    for (final FusionBasePainter painter in painters) {
      final Rect bounds = painter.getBounds(cPainter);
      contentRect = contentRect.expandToInclude(bounds);
    }
    final bool isInitialSetting = contentSize == null;

    this.contentRect = contentRect;
    if (isInitialSetting) {
      fitToScreen();
    }
  }

  void setCanvasSize(Size size) {
    final bool isInitialSetting = _canvasSize == null;

    _canvasSize = size;
    if (isInitialSetting) {
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

  void fitToScreen({EdgeInsets padding = EdgeInsets.zero}) {
    final Rect? contRect = contentRect;
    final Size? contSize = contRect?.size;
    final Size? viewportSize = canvasSize;
    if (contRect == null || contSize == null || viewportSize == null || contSize.width == 0 || contSize.height == 0) return;
    final double availableWidth = (viewportSize.width - padding.left - padding.right).clamp(0.0, double.infinity);
    final double availableHeight = (viewportSize.height - padding.top - padding.bottom).clamp(0.0, double.infinity);
    if (availableWidth == 0 || availableHeight == 0) return;

    final double scaleX = availableWidth / contSize.width;
    final double scaleY = availableHeight / contSize.height;
    final double scale = (scaleX < scaleY ? scaleX : scaleY).clamp(minScale, maxScale);

    // Keep content centered in the padded viewport after scaling.
    final double fittedWidth = contSize.width * scale;
    final double fittedHeight = contSize.height * scale;
    final double targetDx = padding.left + (availableWidth - fittedWidth) / 2 - (contRect.left * scale);
    final double targetDy = padding.top + (availableHeight - fittedHeight) / 2 - (contRect.top * scale);
    final Offset targetOffset = Offset(targetDx, targetDy);

    setCanvasState(state.scaleCanvas(scale, offset: targetOffset - state.offset));
  }
}
