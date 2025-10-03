import 'package:flutter/material.dart';

mixin CanvasHandlerMixin on ChangeNotifier {
  Offset canvasOffset = Offset.zero;
  double canvasScale = 1.0;

  double get minScale => 0.5;
  double get maxScale => 3.0;

  void onPanStart(DragStartDetails details) {
    // Handle pan start if needed
  }

  void onPanUpdate(Offset delta) {
    canvasOffset += delta;
    notifyListeners();
  }

  void onPanEnd(DragEndDetails details) {
    // Handle pan end if needed
    saveState();
  }

  void onScaleStart(ScaleStartDetails details) {
    // Handle scale start if needed
  }

  void onScaleUpdate(double scale, Offset focalPoint) {
    final double oldScale = canvasScale;
    final double newScale = (canvasScale + scale).clamp(minScale, maxScale);

    // Calculate the actual scale change that will be applied
    final double actualScaleChange = newScale / oldScale;

    // Adjust offset to zoom towards focal point
    // The focal point should remain at the same screen position
    canvasOffset = focalPoint - (focalPoint - canvasOffset) * actualScaleChange;

    canvasScale = newScale;
    notifyListeners();
  }

  void onScaleEnd(ScaleEndDetails details) {
    // Handle scale end if needed
    saveState();
  }

  void saveState();
}
