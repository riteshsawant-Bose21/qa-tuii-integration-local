part of '../component_painter.dart';

class BaseComponentPainter extends ComponentDataPainter {
  final CircuitComponent component;
  final ComponentPainter painter;

  BaseComponentPainter({required this.component, required this.painter});
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = component.position & component.size;
    final Paint paint =
        Paint()
          ..color = const Color(0xFFCCCCCC)
          ..style = PaintingStyle.fill;

    // Draw component body
    canvas.drawRect(rect, paint);

    // Draw component border
    final Paint borderPaint =
        Paint()
          ..color =
              component == painter.controller.selectedElement
                  ? Colors.red
                  : const Color(0xFF000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawRect(rect, borderPaint);

    // Draw ports
    final Paint connectedPortPaint =
        Paint()
          ..color = const Color(0xFF0000FF)
          ..style = PaintingStyle.fill;
    final Paint freePortPaint =
        Paint()
          ..color = const Color(0xFF0000FF)
          ..style = PaintingStyle.stroke;
    // TextPainter(
    //   text: TextSpan(text: component.data.label),
    // ).paint(canvas, rect.center);
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
