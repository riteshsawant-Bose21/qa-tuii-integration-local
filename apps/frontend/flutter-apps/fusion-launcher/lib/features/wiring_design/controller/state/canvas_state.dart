import 'package:flutter/services.dart';

abstract class CanvasState {
  final Offset offset;
  final double scale;

  CanvasState({required this.offset, required this.scale});
}

class IdleCanvasState extends CanvasState {
  IdleCanvasState({required super.offset, required super.scale});
}

class CanvasScaleState extends CanvasState {
  CanvasScaleState({required super.offset, required super.scale});
}

class CanvasPanState extends CanvasState {
  CanvasPanState({required super.offset, required super.scale});
}

extension CanvasStateMutation on CanvasState {
  CanvasState pan(Offset delta) {
    return CanvasPanState(offset: offset + delta, scale: scale);
  }

  CanvasState scaleCanvas(double scale, {Offset offset = Offset.zero}) {
    return CanvasScaleState(offset: this.offset + offset, scale: scale);
  }

  CanvasState idle() {
    return IdleCanvasState(offset: offset, scale: scale);
  }
}
