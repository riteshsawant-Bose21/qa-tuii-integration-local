import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/mixin/fusion_canvas_interactable_mixin.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';

class FusionCanvasLayerInteractionSupportUseCase {
  final FusionCanvasPainter painter;

  const FusionCanvasLayerInteractionSupportUseCase({
    required this.painter,
  });

  bool call(String layerId, FusionCanvasLayerInteraction interaction) {
    return painter.supportsLayerInteraction(layerId, interaction);
  }
}
