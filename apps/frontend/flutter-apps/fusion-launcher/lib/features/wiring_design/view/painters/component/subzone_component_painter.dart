part of '../component_painter.dart';

class SubZoneComponentPainter extends ComponentDataPainter {
  final CircuitComponent component;
  final ComponentPainter painter;

  SubZoneComponentPainter({required this.component, required this.painter});
  @override
  void paint(Canvas canvas, Size size) {
    final SubZoneComponentData data = component.data as SubZoneComponentData;
    final Rect rect = component.position & component.size;
    final Paint paint =
        Paint()
          ..color =
              Colors
                  .transparent // const Color(0xFFCCCCCC)
          ..style = PaintingStyle.fill;

    // Draw component body
    canvas.drawRect(rect, paint);

    // Draw component border
    final Paint borderPaint =
        Paint()
          ..color = painter.isSelected(component) ? Colors.red : Colors.grey
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
