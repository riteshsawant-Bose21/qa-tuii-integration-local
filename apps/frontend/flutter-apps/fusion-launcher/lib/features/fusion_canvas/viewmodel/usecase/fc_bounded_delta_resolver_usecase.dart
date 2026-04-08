import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';

class FusionCanvasBoundedDeltaResolverUseCase {
  final FusionCanvasPainter painter;

  const FusionCanvasBoundedDeltaResolverUseCase({
    required this.painter,
  });

  Offset call(String layerId, Offset delta) {
    return painter.getBoundedDeltaForLayer(layerId, delta);
  }
}
