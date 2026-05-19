import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_lib/fusion_lib.dart';

abstract class RectangleToolState extends FusionToolState {}

class IdleRectangleToolState extends RectangleToolState {}

class DrawingRectangleToolState extends RectangleToolState {
  final Offset start;
  final Offset current;

  DrawingRectangleToolState({required this.start, required this.current});

  Rect get rect => Rect.fromPoints(start, current);

  List<FusionCanvasPoint> get points {
    final Rect normalized = rect;
    return <FusionCanvasPoint>[
      FusionCanvasPoint(position: normalized.topLeft),
      FusionCanvasPoint(position: normalized.topRight),
      FusionCanvasPoint(position: normalized.bottomRight),
      FusionCanvasPoint(position: normalized.bottomLeft),
    ];
  }
}

class DrawnRectangleToolState extends RectangleToolState {
  final List<FusionCanvasPoint> points;

  DrawnRectangleToolState({required this.points});
}

class CancelledRectangleToolState extends RectangleToolState {
  final List<FusionCanvasPoint> points;

  CancelledRectangleToolState({required this.points});
}
