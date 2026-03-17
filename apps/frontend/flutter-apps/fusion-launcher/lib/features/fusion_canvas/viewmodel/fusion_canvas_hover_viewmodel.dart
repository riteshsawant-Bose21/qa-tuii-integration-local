import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_hover_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/tool/line_center_handle_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionCanvasHoverViewModel extends Cubit<FusionHoverState> {
  FusionCanvasHoverViewModel() : super(FusionHoverState(hoveredPainterId: null));

  bool _isCenterHandleHovered(
    FusionCanvasElement? hoveredElement,
    FusionBasePainter? hoveredPainter,
    Offset pointerPosition,
    FusionCanvasPainter painters,
  ) {
    if (hoveredElement is! FusionCanvasLine || hoveredPainter == null) {
      return false;
    }

    if (!painters.isSelected(hoveredPainter.id)) {
      return false;
    }

    return LineCenterHandlePainter.isLineCenterHit(
      pointerPosition,
      hoveredElement,
      hoveredPainter,
      painters,
    );
  }

  void updateHoverPosition(Offset? position, FusionCanvasPainter painters) {
    if (position == null) {
      emit(FusionHoverState(hoveredPainterId: null));
    } else {
      final FusionBasePainter? pos = painters.isHit(position);
      if (pos != null) {
        final FusionCanvasElement? hoveredElement = pos.isHit(position, painters);
        emit(
          FusionHoverState(
            hoveredPainterId: pos.id,
            hoveredElement: hoveredElement,
            isCenterHandleHovered: _isCenterHandleHovered(
              hoveredElement,
              pos,
              position,
              painters,
            ),
          ),
        );
        // print("Hovering over painter ${pos.id} and element ${hoveredElement?.id}");
      } else {
        emit(FusionHoverState(hoveredPainterId: null));
      }
    }
  }
}
