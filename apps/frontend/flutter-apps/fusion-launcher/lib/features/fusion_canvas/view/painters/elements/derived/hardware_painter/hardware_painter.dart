import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart' show FusionCanvasPainter;
import 'package:fusion_lib/fusion_lib.dart';

import '../../../fusion_base_painter.dart';
import '../../fusion_canvas_element_painter.dart';

class HardwarePainter extends FusionCanvasElementPainter {
  final HardwareComponent hardware;

  HardwarePainter({required this.hardware}) : super(item: FusionCanvasItem(id: hardware.id));

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final Offset? position = hardware.pos;
    if (position != null) {
      final Rect rect = getTransformedRect(painter);
      final bool didPaint = drawImage(canvas: canvas, imagePath: hardware.image, rect: rect, painter: painter);
      if (!didPaint) {
        final bool didPaint = drawImage(canvas: canvas, imagePath: 'assets/icons/building_page/no-image.png', rect: rect, painter: painter);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is! HardwarePainter) return true;
    return oldDelegate.hardware != hardware;
  }

  @override
  Offset getOffset() => hardware.pos ?? Offset.zero;

  @override
  Size getSize() => const Size.square(120);
}
