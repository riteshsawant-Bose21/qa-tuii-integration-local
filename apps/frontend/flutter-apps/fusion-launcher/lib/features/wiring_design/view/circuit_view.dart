import 'dart:developer';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/wiring_design/controller/circuit_controller.dart';
import 'package:fusion_launcher/features/wiring_design/view/painters/circuit_painter.dart';
import 'package:provider/provider.dart';

class CircuitView extends StatelessWidget {
  const CircuitView({super.key, required this.controller});
  final CircuitController controller;
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CircuitController>.value(
      value: controller,
      child: Consumer<CircuitController>(
        builder: (
          BuildContext context,
          CircuitController controller,
          Widget? child,
        ) {
          final CircuitPainter circuitPainter = CircuitPainter(controller);
          return Listener(
            onPointerPanZoomUpdate: (PointerPanZoomUpdateEvent event) {
              controller.onScaleUpdate(event.scale);
            },
            onPointerSignal: (PointerSignalEvent event) {
              if (event is PointerScrollEvent) {
                controller.onScaleUpdate(
                  event.scrollDelta.distance *
                      0.001 *
                      event.scrollDelta.direction,
                );
              }
            },
            child: ClipRect(
              child: GestureDetector(
                onTapUp: (TapUpDetails details) {
                  final dynamic value = circuitPainter.isHit(
                    circuitPainter.correctPosition(details.localPosition),
                  );
                  controller.selectElement(value);
                  log('Hit: $value');
                },
                onPanStart: (DragStartDetails details) {
                  log('Pan Start: ${details.localPosition}');
                  final Offset correctedPos = circuitPainter.correctPosition(
                    details.localPosition,
                  );
                  log('Corrected Pos: $correctedPos');
                  final dynamic value = circuitPainter.isHit(correctedPos);

                  controller.onMoveStart(value, correctedPos);
                },
                onPanUpdate: (DragUpdateDetails details) {
                  controller.onMoveUpdate(
                    details.delta / controller.canvasScale,
                  );
                },
                onPanEnd: (DragEndDetails details) {
                  final Offset correctedPos = circuitPainter.correctPosition(
                    details.localPosition,
                  );
                  final dynamic value = circuitPainter.isHit(correctedPos);
                  controller.onMoveEnd(value, correctedPos);
                },
                child:  CustomPaint(
                  size: Size.infinite,
                  painter: circuitPainter,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
