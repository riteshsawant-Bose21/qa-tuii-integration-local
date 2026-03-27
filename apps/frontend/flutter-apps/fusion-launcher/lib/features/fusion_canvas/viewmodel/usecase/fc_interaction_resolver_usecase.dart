import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/mixin/fusion_canvas_interactable_mixin.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';

class FusionCanvasInteractionResolverUseCase {
  final FusionCanvasPainter painter;

  const FusionCanvasInteractionResolverUseCase({
    required this.painter,
  });

  FusionCanvasInteractionTarget? call(
    Offset position,
    FusionCanvasLayerInteraction interaction,
  ) {
    return painter.getInteractionTargetAt(position, interaction);
  }
}
