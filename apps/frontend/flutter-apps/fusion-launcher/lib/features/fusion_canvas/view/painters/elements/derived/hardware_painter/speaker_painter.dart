import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../fusion_canvas_element_painter.dart';

class SpeakerPainter extends FusionCanvasElementPainter {
  final Speaker hardware;

  SpeakerPainter({required this.hardware}) : super(item: FusionCanvasItem(id: hardware.id));
  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final Offset? position = hardware.pos;
    if (position != null) {
      final Rect rect = getTransformedRect(painter);

      _drawSpeaker(rect, canvas, painter, hardware);
    }
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is! SpeakerPainter) return true;
    return oldDelegate.hardware != hardware;
  }

  void _drawSpeaker(Rect rect, Canvas canvas, FusionCanvasPainter painter, Speaker speaker) {
    final Paint paint = Paint()..color = painter.context.colorScheme.black;

    final MountingType? mountingType = speaker.mountingType;
    switch (mountingType) {
      case MountingType.surface:
        return canvas.drawRect(rect, paint);
      case MountingType.pendant:
        return canvas.drawPath(
          Path()
            ..moveTo(rect.topCenter.dx, rect.topCenter.dy)
            ..lineTo(rect.bottomRight.dx, rect.bottomRight.dy)
            ..lineTo(rect.bottomLeft.dx, rect.bottomLeft.dy)
            ..close(),
          paint,
        );
      case MountingType.ceiling:
      case null:
        return canvas.drawCircle(rect.center, rect.width / 2, paint);
    }
  }

  @override
  Offset getOffset() => hardware.pos ?? Offset.zero;

  @override
  Size getSize() => const Size.square(30);

}
