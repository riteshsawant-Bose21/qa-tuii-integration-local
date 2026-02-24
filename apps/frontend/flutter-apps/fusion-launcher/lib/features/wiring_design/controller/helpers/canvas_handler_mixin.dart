import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/wiring_design/controller/state/canvas_state.dart';

mixin CanvasHandlerMixin on ChangeNotifier {
  CanvasState get canvasState;

  double get minScale => 0.25;
  double get maxScale => 2.0;

  Size? canvasSize;

  bool isWithinViewport(Offset position) {
    final Rect rect = (canvasState.offset & ((canvasSize ?? const Size(100, 100)) * canvasState.scale));
    final bool contains = rect.contains(
      position,
    );
    return contains;
  }

  void recenter(Offset center) {
    setCanvasState(
      canvasState.recenter(
        center,
        ((canvasSize ?? const Size(100, 100))),
      ),
    );
  }

  void onPanStart(DragStartDetails details) {
    // Handle pan start if needed
  }

  void onPanUpdate(Offset delta) {
    setCanvasState(canvasState.pan(delta * (canvasState.scale)));
    notifyListeners();
  }

  void onPanEnd(DragEndDetails details) {
    setCanvasState(canvasState.idle());

    saveState();
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
    final double oldScale = canvasState.scale;
    final double newScale = (canvasState.scale + diffScale).clamp(
      minScale,
      maxScale,
    );

    // Calculate the actual scale change that will be applied
    final double actualScaleChange = newScale / oldScale;

    // Adjust offset to zoom towards focal point
    // The focal point should remain at the same screen position
    final Offset delta = (focalPoint - (focalPoint - canvasState.offset) * actualScaleChange) - canvasState.offset;
    setCanvasState(canvasState.scaleCanvas(newScale, offset: delta));

    notifyListeners();
  }

  void onScaleEnd(ScaleEndDetails details) {
    // Handle scale end if needed
    setCanvasState(canvasState.idle());
    saveState();
    _startScale = null;
  }

  void saveState();

  void setCanvasState(CanvasState state);
}
