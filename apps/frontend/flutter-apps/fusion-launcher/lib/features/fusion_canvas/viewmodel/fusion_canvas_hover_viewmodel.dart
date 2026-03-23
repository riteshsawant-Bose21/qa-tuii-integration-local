import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_hover_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/tool/line_center_handle_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../view/painters/elements/mixin/fusion_canvas_interactable_mixin.dart';

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
      final FusionCanvasInteractionTarget? target = painters.getInteractionTargetAt(
        position,
        FusionCanvasLayerInteraction.select,
      );
      if (target != null) {
        final FusionCanvasInteractibleMixin pos = target.painter;
        final FusionCanvasElement hoveredElement = target.element;
        emit(
          FusionHoverState(
            hoveredPainterId: pos.id,
            hoveredElement: hoveredElement,
            hoveredPainterInteractions: pos.possibleInteractions,
            // Let the element override its own interactions (e.g. a point
            // within a non-draggable layer can still be draggable).
            hoveredElementInteractions: pos.possibleInteractionsForElement(
              hoveredElement,
            ),
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
