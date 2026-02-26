import 'package:flutter/services.dart';

abstract class FusionCanvasState {
  final Offset offset;
  final double scale;

  FusionCanvasState({required this.offset, required this.scale});
}

class IdleFusionCanvasState extends FusionCanvasState {
  IdleFusionCanvasState({required super.offset, required super.scale});
}

class FusionCanvasScaleState extends FusionCanvasState {
  FusionCanvasScaleState({required super.offset, required super.scale});
}

class FusionCanvasPanState extends FusionCanvasState {
  FusionCanvasPanState({required super.offset, required super.scale});
}

extension FusionCanvasStateMutation on FusionCanvasState {
  FusionCanvasState pan(Offset delta) {
    return FusionCanvasPanState(offset: offset + delta, scale: scale);
  }

  FusionCanvasState scaleCanvas(double scale, {Offset offset = Offset.zero}) {
    return FusionCanvasScaleState(offset: this.offset + offset, scale: scale);
  }

  FusionCanvasState idle() {
    return IdleFusionCanvasState(offset: offset, scale: scale);
  }

  FusionCanvasState recenter(Offset center, Size size) {
    return IdleFusionCanvasState(
      offset: -center * scale + Offset(size.width, size.height),
      scale: scale,
    );
  }
}
