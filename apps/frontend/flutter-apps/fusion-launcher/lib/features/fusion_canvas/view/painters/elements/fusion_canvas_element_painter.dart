import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../fusion_base_painter.dart';

abstract class FusionCanvasElementPainter extends FusionBasePainter {
  final FusionCanvasItem item;

  @override
  String? get id => item.id;
  Offset getOffset();
  Size getSize();

  Rect getRect() {
    return getOffset() & getSize();
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

  FusionCanvasElementPainter({required this.item});

  @override
  FusionCanvasElement? isHit(Offset position, FusionCanvasPainter painter) {
    final Rect elementRect = getTransformedRect(painter);
    print("Rect : $elementRect");
    // print("Is hit check for ${item.id} at position $position with elementRect $elementRect");
    if (elementRect.contains(position)) {
      // print("Is hit check for ${item.id} at position $position with elementRect $elementRect - hit");
      return item;
    }
    // print("Is hit check for ${item.id} at position $position with elementRect $elementRect - not hit");
    return null;
  }
}
