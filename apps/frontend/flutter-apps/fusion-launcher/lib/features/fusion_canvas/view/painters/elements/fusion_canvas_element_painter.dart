import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/mixin/fusion_canvas_interactable_mixin.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../fusion_base_painter.dart';

abstract class FusionCanvasElementPainter extends FusionBasePainter with FusionCanvasInteractibleMixin {
  final FusionCanvasItem item;

  @override
  String? get id => item.id;
  Offset getOffset();
  Size getSize();

  Rect getRect() {
    final Size size = getSize();
    return Rect.fromCenter(center: getOffset(), width: size.width, height: size.height);
  }

  Rect getTransformedRect(FusionCanvasPainter painter) {
    final Offset offset = getOffset();
    final Size size = getSize();
    return Rect.fromCenter(
      center: transformOffsetForLayer(offset, painter, id),
      width: nonScaling(size.width, painter),
      height: nonScaling(size.height, painter),
    );
  }

  @override
  Rect getBounds(FusionCanvasPainter painter) {
    return getTransformedRect(painter);
  }

  FusionCanvasElementPainter({required this.item});

  @override
  FusionCanvasElement? isHit(Offset position, FusionCanvasPainter painter) {
    final Rect elementRect = getTransformedRect(painter);
    if (elementRect.contains(position)) {
      return item;
    }
    return null;
  }
}
