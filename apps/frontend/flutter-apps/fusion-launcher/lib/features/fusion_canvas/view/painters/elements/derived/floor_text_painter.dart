import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/fusion_canvas_element_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FloorTextPainter extends FusionCanvasElementPainter {
  final FloorText floorText;

  FloorTextPainter({required this.floorText}) : super(item: FusionCanvasItem(id: floorText.id));

  @override
  String get id => floorText.id;

  @override
  Offset getOffset() => floorText.position.position;

  @override
  Size getSize() {
    // Fixed bounds keep selection/hit behavior predictable regardless of zoom level.
    return Size(
      (floorText.text.length * (floorText.fontSize * 0.65)).clamp(48.0, 420.0).toDouble(),
      (floorText.fontSize * 1.8).clamp(24.0, 96.0).toDouble(),
    );
  }

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final Rect rect = getTransformedRect(painter);
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: floorText.text,
        style: TextStyle(
          color: painter.context.colorScheme.primary,
          fontSize: floorText.fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: rect.width);

    final Offset paintOffset = Offset(rect.left, rect.center.dy - (textPainter.height / 2));
    textPainter.paint(canvas, paintOffset);
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is! FloorTextPainter) return true;
    return oldDelegate.floorText != floorText;
  }
}
