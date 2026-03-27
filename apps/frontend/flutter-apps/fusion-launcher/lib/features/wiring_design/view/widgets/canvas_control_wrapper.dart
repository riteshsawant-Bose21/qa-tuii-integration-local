import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/wiring_design/controller/state/wiring_state.dart';

import '../../controller/circuit_controller.dart';
import '../../model/canvas_element.dart';
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
    return GestureDetector(
      onScaleStart: (ScaleStartDetails details) {
        controller.onScaleStart(details);
      },
      onScaleUpdate: (ScaleUpdateDetails details) {
        controller.onScaleUpdate(details.scale, details.focalPoint);
      },
      onScaleEnd: (ScaleEndDetails details) {
        controller.onScaleEnd(details);
      },
      child: Listener(
        onPointerSignal: (PointerSignalEvent event) {
          if (event is PointerScrollEvent) {
            controller.onScaleUpdate(
              event.scrollDelta.distance * 0.001 * -event.scrollDelta.direction,
              event.localPosition,
            );
          }
        },
        onPointerMove: (PointerMoveEvent event) {
          if (controller.state is IdleWiringState) {
            final Offset correctedPos = circuitPainter.correctPosition(
              event.localPosition,
            );
            final CanvasElement? value = circuitPainter.isHit(correctedPos);
            if (value != null) {
              controller.onMoveStart(value, correctedPos);
            } else {
              controller.onMoveUpdate(
                event.delta / controller.canvasState.scale,
              );
            }
          } else if (controller.state is ElementSelectionState) {
            final Offset correctedPos = circuitPainter.correctPosition(
              event.localPosition,
            );
            final CanvasElement? value = circuitPainter.isHit(correctedPos);
            if (value != null) {
              controller.onMoveStart(value, correctedPos);
            } else {
              controller.onMoveUpdate(
                event.delta / controller.canvasState.scale,
              );
            }
          } else {
            controller.onMoveUpdate(event.delta / controller.canvasState.scale);
          }
        },
        onPointerUp: (PointerUpEvent event) {
          final Offset correctedPos = circuitPainter.correctPosition(
            event.localPosition,
          );
          final dynamic value = circuitPainter.isHit(correctedPos);
          if (controller.state is ElementMovingState || controller.state is ConnectionProgressWiringState) {
            controller.onMoveEnd(value, correctedPos);
          } else {
            controller.selectElement(value);
          }
        },

        child: ClipRect(
          child: child,
        ),
      ),
    );
  }
}
