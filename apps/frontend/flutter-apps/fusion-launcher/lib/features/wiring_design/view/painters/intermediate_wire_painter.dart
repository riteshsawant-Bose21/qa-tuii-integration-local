import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/wiring_design/model/canvas_element.dart';
import 'package:fusion_launcher/features/wiring_design/model/circuit_port.dart';

import 'base_painter.dart';

class IntermediateWirePainter extends BasePainter {
  final CircuitPort start;
  final List<Offset> joints;
  final Offset end;

  IntermediateWirePainter({
    required this.start,
    required this.end,
    required this.joints,
    this.path,
    required super.controller,
  });
  Path? path;
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = const Color(0xFF000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5;
    path = Path();
    path!.moveTo(start.absolutePosition.dx, start.absolutePosition.dy);
    path!.lineTo(
      start.absolutePositionWithOffset.dx,
      start.absolutePositionWithOffset.dy,
    );

    for (int i = 0; i < joints.length; i++) {
      path!.lineTo(joints[i].dx, joints[i].dy);
    }
    path!.lineTo(end.dx, end.dy);

    canvas.drawPath(path!, paint);
  }

  @override
  CanvasElement? isHit(Offset position) {
    return null;
  }
}
