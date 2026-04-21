import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SplLoaderPainter extends FusionBasePainter {
  final Animation<double> animation;
  final List<ListeningArea> listeningAreas;
  SplLoaderPainter({
    required this.animation,
    required this.listeningAreas,
  });

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    ///
    /// Paint shimmer for all listing area
    ///
    /// For each listening area, we will create a shimmer effect that moves from left to right
    for (final ListeningArea listeningArea in listeningAreas) {
      final Path? tmpPath = getPolygonPath(FusionCanvasPolygon(points: listeningArea.vertices, id: listeningArea.id), painter);
      if (tmpPath == null) {
        print("Skipping area ${listeningArea.name} due to invalid path.");
        continue;
      }
      // final double spl = listeningArea.splData ?? 0.0;

      // Create a gradient that moves from left to right
      final Rect bounds = tmpPath.getBounds();
      // final double shimmerWidth = bounds.width / 2; // Width of the shimmer effect
      // final double shimmerPosition = (animation.value * (bounds.width + shimmerWidth)) - shimmerWidth; // Calculate the current position of the shimmer

      final Paint shimmerPaint =
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(bounds.left - bounds.width + (bounds.width * 2) * animation.value, bounds.top),
              Offset(bounds.left + (bounds.width * 2) * animation.value, bounds.top),
              <Color>[Colors.grey.shade300, Colors.grey, Colors.grey.shade300],
              <double>[0.0, 0.5, 1.0],
            );

      canvas.drawPath(tmpPath, shimmerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    return true;
  }
}
