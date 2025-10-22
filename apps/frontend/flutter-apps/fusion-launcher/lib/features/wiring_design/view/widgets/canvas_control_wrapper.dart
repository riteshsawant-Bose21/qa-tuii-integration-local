import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/wiring_design/model/canvas_element.dart';

import '../../controller/circuit_controller.dart';
import '../painters/circuit_painter.dart';

class CanvasControlWrapper extends StatelessWidget {
  const CanvasControlWrapper({
    super.key,
    required this.controller,
    required this.circuitPainter,
    required this.child,
  });
  final CircuitController controller;
  final CircuitPainter circuitPainter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerPanZoomUpdate: (PointerPanZoomUpdateEvent event) {
        if (event.scale == 1) return;
        controller.onScaleUpdate(
          event.scale - controller.state.canvasState.scale,
          event.localPosition,
        );
      },
      onPointerSignal: (PointerSignalEvent event) {
        if (event is PointerScrollEvent) {
          controller.onScaleUpdate(
            event.scrollDelta.distance * 0.001 * event.scrollDelta.direction,
            event.localPosition,
          );
        }
      },
      child: ClipRect(
        child: GestureDetector(
          onTapUp: (TapUpDetails details) {
            final CanvasElement? value = circuitPainter.isHit(
              circuitPainter.correctPosition(details.localPosition),
            );
            controller.selectElement(value);
            // onTap(circuitPainter.correctPosition(details.localPosition));
          },
          onPanStart: (DragStartDetails details) {
            final Offset correctedPos = circuitPainter.correctPosition(
              details.localPosition,
            );
            final dynamic value = circuitPainter.isHit(correctedPos);

            controller.onMoveStart(value, correctedPos);
          },
          onPanUpdate: (DragUpdateDetails details) {
            controller.onMoveUpdate(
              details.delta / controller.canvasState.scale,
            );
          },
          onPanEnd: (DragEndDetails details) {
            final Offset correctedPos = circuitPainter.correctPosition(
              details.localPosition,
            );
            final dynamic value = circuitPainter.isHit(correctedPos);
            controller.onMoveEnd(value, correctedPos);
          },
          child: child,
        ),
      ),
    );
  }
}
