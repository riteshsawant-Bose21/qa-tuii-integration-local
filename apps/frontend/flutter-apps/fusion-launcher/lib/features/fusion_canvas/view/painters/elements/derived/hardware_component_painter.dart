import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../fusion_canvas_element_painter.dart';
import '../mixin/fusion_canvas_bounded_movement.dart';
import 'listening_area_painter.dart';

class HardwareComponentPainter extends FusionCanvasElementPainter with FusionCanvasBoundedMovement {
  final HardwareComponent hardware;

  HardwareComponentPainter({required this.hardware}) : super(item: FusionCanvasItem(id: hardware.id));
  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final Offset? position = hardware.pos;
    if (position != null) {
      final Rect rect = getTransformedRect(painter);

      if (hardware is Speaker) {
        _drawSpeaker(rect, canvas, painter, hardware as Speaker);
      } else if (hardware is Source) {}
      // canvas.drawRect(rect, Paint()..color = painter.context.colorScheme.black);
    }
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is! HardwareComponentPainter) return true;
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

  @override
  Path getBoundPath(FusionCanvasPainter painter) {
    final String? listiningAreaId = hardware.locationEntity.listeningAreaId;
    final ListeningAreaPainter? listingAreaPainter =
        painter.layers.whereType<ListeningAreaPainter>().where((ListeningAreaPainter p) => p.id == listiningAreaId).firstOrNull;
    return listingAreaPainter?.getPath(painter) ?? Path()
      ..addRect(getTransformedRect(painter));
  }
}
