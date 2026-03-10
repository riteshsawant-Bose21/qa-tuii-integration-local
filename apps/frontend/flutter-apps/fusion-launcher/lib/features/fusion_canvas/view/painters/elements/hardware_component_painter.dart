import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'fusion_canvas_element_painter.dart';

class HardwareComponentPainter extends FusionCanvasElementPainter {
  final HardwareComponent hardware;

  HardwareComponentPainter({required this.hardware}) : super(item: FusionCanvasItem(id: hardware.id));
  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final Offset? position = hardware.pos;
    if (position != null) {
      final Rect rect = getTransformedRect(painter);

      canvas.drawRect(rect, Paint()..color = painter.context.colorScheme.black);
    }
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is! HardwareComponentPainter) return true;
    return oldDelegate.hardware != hardware;
  }

  @override
  Offset getOffset() => hardware.pos ?? Offset.zero;

  @override
  Size getSize() => const Size.square(30);
}
