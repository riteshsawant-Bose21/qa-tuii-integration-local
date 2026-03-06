import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_hover_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';

class FusionCanvasHoverViewModel extends Cubit<FusionHoverState> {
  FusionCanvasHoverViewModel() : super(FusionHoverState(hoveredPainterId: null));

  void updateHoverPosition(Offset? position, FusionCanvasPainter painters) {
    if (position == null) {
      emit(FusionHoverState(hoveredPainterId: null));
    } else {
      final FusionBasePainter? pos = painters.isHit(position);
      if (pos != null) {
        emit(
          FusionHoverState(
            hoveredPainterId: pos.id,
            hoveredElement: pos.isHit(position, painters),
          ),
        );
      } else {
        emit(FusionHoverState(hoveredPainterId: null));
      }
    }
  }
}
