import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/mixin/fusion_canvas_interactable_mixin.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';

class FusionCanvasSelectableLayersInRectUseCase {
  final FusionCanvasPainter painter;

  const FusionCanvasSelectableLayersInRectUseCase({
    required this.painter,
  });

  Set<String> call(Rect rect) {
    final Rect normalized = Rect.fromLTRB(
      rect.left < rect.right ? rect.left : rect.right,
      rect.top < rect.bottom ? rect.top : rect.bottom,
      rect.left > rect.right ? rect.left : rect.right,
      rect.top > rect.bottom ? rect.top : rect.bottom,
    );

    return painter.layers
        .where((FusionBasePainter layer) => layer.id != null)
        .where(
          (FusionBasePainter layer) => painter.supportsLayerInteraction(
            layer.id!,
            FusionCanvasLayerInteraction.select,
          ),
        )
        .where(
          (FusionBasePainter layer) => layer.getBounds(painter).overlaps(normalized),
        )
        .map((FusionBasePainter layer) => layer.id!)
        .toSet();
  }
}
