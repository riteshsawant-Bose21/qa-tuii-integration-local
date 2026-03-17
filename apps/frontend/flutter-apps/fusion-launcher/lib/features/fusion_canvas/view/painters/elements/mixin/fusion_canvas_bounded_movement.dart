import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';

mixin FusionCanvasBoundedMovement on FusionBasePainter {
  Path getBoundPath(FusionCanvasPainter painter);

  Offset getBoundedOffset(Offset desiredOffset, FusionCanvasPainter painter) {
    final Path boundPath = getBoundPath(painter);
    if (boundPath.contains(desiredOffset)) {
      return desiredOffset;
    } else {
      // If the desired offset is outside the bounds, find the closest point on the path
      final PathMetrics pathMetrics = boundPath.computeMetrics();
      double minDistance = double.infinity;
      Offset closestPoint = desiredOffset;

      for (final PathMetric pathMetric in pathMetrics) {
        final Tangent? tangent = pathMetric.getTangentForOffset(pathMetric.length * 0.5);
        if (tangent != null) {
          final Offset pointOnPath = tangent.position;
          final double distance = (pointOnPath - desiredOffset).distance;
          if (distance < minDistance) {
            minDistance = distance;
            closestPoint = pointOnPath;
          }
        }
      }
      return closestPoint;
    }
  }

  Offset getBoundedDelta(Offset delta, FusionCanvasPainter painter) {
    final Rect rect = getBounds(painter);
    final Offset currentOffset = rect.center;
    final Offset desiredOffset = currentOffset + delta;

    final Offset boundedOffset = getBoundedOffset(desiredOffset, painter);
    print('Current Offset: $currentOffset, Desired Offset: $desiredOffset Bounded Offset: $boundedOffset');
    return boundedOffset - currentOffset;
  }
}
