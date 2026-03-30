import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/connection_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../fusion_canvas_painter.dart';

/// Paints the in-progress orthogonal path while the user is dragging a port.
class ConnectionToolPainter extends FusionBasePainter {
  final ConnectingToolState state;

  ConnectionToolPainter({required this.state});

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final List<Offset> path = state.path;
    if (path.length < 2) return;

    final double strokeWidth = nonScaling(3.0, painter);

    // ── Wire path ─────────────────────────────────────────────────────────
    final Paint linePaint =
        Paint()
          ..color = painter.context.colorScheme.primary.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    final Path drawPath = Path()..moveTo(path.first.dx, path.first.dy);
    for (int i = 1; i < path.length; i++) {
      drawPath.lineTo(path[i].dx, path[i].dy);
    }
    canvas.drawPath(drawPath, linePaint);

    // ── Endpoint indicator (filled circle at current mouse position) ──────
    final double radius = nonScaling(6.0, painter);
    canvas.drawCircle(
      state.currentPosition,
      radius,
      Paint()
        ..color = painter.context.colorScheme.primary
        ..style = PaintingStyle.fill,
    );

    // ── Source port indicator (ring at drag origin) ────────────────────────
    canvas.drawCircle(
      state.sourcePosition,
      radius,
      Paint()
        ..color = painter.context.colorScheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is! ConnectionToolPainter) return true;
    return oldDelegate.state != state;
  }
}
