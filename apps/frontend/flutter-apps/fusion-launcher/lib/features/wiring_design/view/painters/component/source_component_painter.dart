part of '../component_painter.dart';

class SourceComponentPainter extends ComponentDataPainter {
  final CircuitComponent component;
  final ComponentPainter painter;

  SourceComponentPainter({required this.component, required this.painter});
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = component.position & component.size;

    // Draw component border
    final Paint borderPaint =
        Paint()
          ..color = const Color(0xFF000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    if (painter.isSelected(component)) {
      canvas.drawRect(rect, borderPaint);
    }

    painter.drawImage(
      canvas: canvas,
      path: component.data.image ?? "",
      rect: rect.deflate(rect.width * 0.25),
    );

    painter.drawText(
      canvas: canvas,
      text: component.data.label,
      position: rect.bottomCenter - Offset(0, rect.height * 0.1),
    );

    // Draw ports
    final Paint connectedPortPaint =
        Paint()
          ..color = painter.colorScheme.activePortBG
          ..style = PaintingStyle.fill;
    final Paint freePortPaint =
        Paint()
          ..color = painter.colorScheme.inactivePortBG
          ..strokeWidth = WiringViewConstants.portRadius * 0.10
          ..style = PaintingStyle.stroke;
    for (final CircuitPort port in component.ports) {
      final Path portPath = Path();
      portPath.addOval(
        Rect.fromCircle(
          center: component.position + port.relativePosition,
          radius: 5,
        ),
      );
      canvas.drawPath(
        portPath,
        painter.hasConnection(port) ? connectedPortPaint : freePortPaint,
      );
    }
  }
}
