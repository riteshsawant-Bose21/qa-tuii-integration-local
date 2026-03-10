part of '../component_painter.dart';

class ZoneComponentPainter extends ComponentDataPainter {
  final CircuitComponent component;
  final ComponentPainter painter;

  ZoneComponentPainter({required this.component, required this.painter});
  @override
  void paint(Canvas canvas, Size size) {
    if (component.children.isEmpty) return;
    final ZoneComponentData data = component.data as ZoneComponentData;
    final Rect rect = component.position & component.size;
    final Paint paint =
        Paint()
          ..color = data.zone.color.withAlpha(90) // const Color(0xFFCCCCCC)
          ..style = PaintingStyle.fill;

    // Draw component body
    canvas.drawRect(rect, Paint()..color = Colors.white);
    canvas.drawRect(rect, paint);

    // Draw component border
    final Paint borderPaint =
        Paint()
          ..color = painter.isSelected(component) ? Colors.red : data.zone.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawRect(rect, borderPaint);

    painter.drawText(
      canvas: canvas,
      text: data.zone.name,
      position: component.position + const Offset(10, 10),
      positionAlignment: Alignment.topLeft,
    );
  }
}
