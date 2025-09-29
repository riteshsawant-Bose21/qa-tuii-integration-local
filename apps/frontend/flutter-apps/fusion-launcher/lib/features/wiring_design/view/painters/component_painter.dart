import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/wiring_design/model/canvas_element.dart';
import 'package:fusion_launcher/features/wiring_design/model/circuit_component.dart';
import 'package:fusion_launcher/features/wiring_design/model/model.dart';
import 'package:fusion_launcher/features/wiring_design/view/painters/base_painter.dart';

class ComponentPainter extends BasePainter {
  final CircuitComponent component;

  ComponentPainter({required this.component, required super.controller});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = component.position & component.size;
    final Paint paint = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..style = PaintingStyle.fill;

    // Draw component body
    canvas.drawRect(rect, paint);

    // Draw component border
    final Paint borderPaint = Paint()
      ..color = component == controller.selectedElement
          ? Colors.red
          : const Color(0xFF000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect, borderPaint);

    // Draw ports
    final Paint portPaint = Paint()
      ..color = const Color(0xFF0000FF)
      ..style = PaintingStyle.fill;

    for (final CircuitPort port in component.ports) {
      final Path portPath = Path();
      portPath.addOval(
        Rect.fromCircle(
          center: component.position + port.relativePosition,
          radius: 5,
        ),
      );
      canvas.drawPath(portPath, portPaint);
    }
  }

  @override
  CanvasElement? isHit(Offset position) {
    for (final CircuitPort port in component.ports) {
      final Rect portRect = Rect.fromCircle(
        center: component.position + port.relativePosition,
        radius: 10,
      );
      if (portRect.contains(position)) {
        return port;
      }
    }
    final Rect rect = component.position & component.size;
    if (rect.contains(position)) {
      return component;
    }
    return null;
  }
}
