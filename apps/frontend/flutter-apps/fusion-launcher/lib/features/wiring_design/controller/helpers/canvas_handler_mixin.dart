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
  }

  void onScaleStart(ScaleStartDetails details) {
    // Handle scale start if needed
  }

  void onScaleUpdate(double scale) {
    canvasScale += scale;
    canvasScale = canvasScale.clamp(minScale, maxScale);
    notifyListeners();
  }

  void onScaleEnd(ScaleEndDetails details) {
    // Handle scale end if needed
  }

  void saveState();
}
