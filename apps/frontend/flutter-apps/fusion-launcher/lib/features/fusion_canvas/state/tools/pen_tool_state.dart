import 'package:fusion_lib/fusion_lib.dart';

import '../fusion_tool_state.dart';

abstract class PenToolState extends FusionToolState {
  // final List<FusionCanvasPoint> points;

  // PenToolState({required this.points});
}

class IdlePenToolState extends PenToolState {}

class DrawingPenToolState extends PenToolState {
  final List<FusionCanvasPoint> points;

  DrawingPenToolState({required this.points});
}

class ClosedPenToolState extends DrawingPenToolState {
  ClosedPenToolState({required super.points});
}

extension PenToolStateExtension on PenToolState {
  PenToolState addPoint(FusionCanvasPoint point) {
    if (this is ClosedPenToolState) {

      return DrawingPenToolState(points: <FusionCanvasPoint>[point]);
    }
    final List<FusionCanvasPoint> existingPoints = this is DrawingPenToolState ? (this as DrawingPenToolState).points : <FusionCanvasPoint>[];
    final List<FusionCanvasPoint> updatedPoints = List<FusionCanvasPoint>.from(existingPoints)..add(point);

    if (_isPathClosed(updatedPoints)) {
      return ClosedPenToolState(points: updatedPoints);
    } else {
      return DrawingPenToolState(points: updatedPoints);
    }
  }

  bool _isPathClosed(List<FusionCanvasPoint> points) {
    if (points.length < 3) return false; // A closed path requires at least 3 points
    final FusionCanvasPoint firstPoint = points.first;
    final FusionCanvasPoint lastPoint = points.last;
    const double threshold = 10.0; // Distance threshold to consider points as "close enough"
    final double distance = (firstPoint.position - lastPoint.position).distance;
    return distance <= threshold;
  }
}
