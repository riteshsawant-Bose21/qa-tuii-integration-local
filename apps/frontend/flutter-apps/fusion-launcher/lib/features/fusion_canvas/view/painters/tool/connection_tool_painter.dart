import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/connection_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/wiring/connection_color_util.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/wiring_design/usecase/connection_usecase.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../elements/wiring/port_painter.dart';
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
    final Color lineColor = ConnectionColorUtil.getColorForPortType(state.sourcePort.port.type);
    // ── Wire path ─────────────────────────────────────────────────────────
    final Paint linePaint =
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    final Path drawPath = Path()..moveTo(path.first.dx, path.first.dy);
    for (int i = 1; i < path.length; i++) {
      drawPath.lineTo(path[i].dx, path[i].dy);
    }
    canvas.drawPath(drawPath, linePaint);
    final double radius = 20;

    // ── Source port indicator (ring at drag origin) ────────────────────────
    canvas.drawCircle(
      state.sourcePosition,
      radius,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // ── Endpoint indicator (filled circle at current mouse position) ──────

    final Alignment alignment = state.sourcePort.portAlignment;
    final double arrowAngle = switch (alignment) {
      Alignment.centerLeft => 180,
      Alignment.centerRight => 0,
      Alignment.topCenter => 90,
      Alignment.bottomCenter => -90,
      _ => 0,
    };
    final FusionCanvasElement? hovered = painter.hoverViewModel.hoveredElement;
    final bool isHoveredPort = hovered is WiringPortData && hovered.id != state.sourcePort.id;
    bool isCompatible = false;
    if (hovered is WiringPortData) {
      isCompatible = ConnectionUseCase().isCompatible(state.sourcePort.port.type, hovered.port.type);
    }
    if (isHoveredPort && !isCompatible) {
      canvas.drawCircle(
        state.currentPosition,
        radius,
        Paint()
          ..color = painter.context.colorScheme.white
          ..style = PaintingStyle.fill,
      );
      final Paint errorPaint =
          Paint()
            ..color = Colors.red
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth;
      canvas.drawCircle(
        state.currentPosition,
        radius,
        errorPaint,
      );
      final Rect rect = Rect.fromCircle(center: state.currentPosition, radius: radius * 0.5);
      canvas.drawLine(rect.centerLeft, rect.centerRight, errorPaint);
    } else {
      canvas.drawCircle(
        state.currentPosition,
        radius,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.fill,
      );
      canvas.save();
      canvas.translate(state.currentPosition.dx, state.currentPosition.dy);
      canvas.rotate(arrowAngle * 3.1415926535 / 180);
      canvas.translate(-state.currentPosition.dx, -state.currentPosition.dy);

      drawImage(
        canvas: canvas,
        imagePath: 'assets/icons/wiring_ports/arrow-right.png',
        rect: Rect.fromCircle(center: state.currentPosition, radius: radius * 0.75),
        painter: painter,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is! ConnectionToolPainter) return true;
    return oldDelegate.state != state;
  }
}
