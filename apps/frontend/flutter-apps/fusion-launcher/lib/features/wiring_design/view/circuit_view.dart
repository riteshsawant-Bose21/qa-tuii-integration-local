import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/wiring_design/controller/circuit_controller.dart';
import 'package:fusion_launcher/features/wiring_design/controller/state/wiring_state.dart';
import 'package:fusion_launcher/features/wiring_design/model/circuit_port.dart';
import 'package:fusion_launcher/features/wiring_design/view/painters/circuit_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:provider/provider.dart';

import 'port_connection/port_connection_overlay.dart';
import 'widgets/canvas_control_wrapper.dart';
import 'widgets/overlay_container.dart';

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
          final CircuitPainter circuitPainter = CircuitPainter(
            controller,
            context.colorScheme,
          );
          Widget? overlay;
          if (controller.state is ElementSelectionState) {
            final ElementSelectionState selectionState =
                controller.state as ElementSelectionState;
            if (selectionState.element is CircuitPort) {
              final CircuitPort port = selectionState.element as CircuitPort;
              final Offset transformedPos = circuitPainter.transformPosition(
                port.position,
              );
              Offset resultedPosition = transformedPos;
              final double width = 200; //* controller.canvasScale;
              final double padding = 30 * controller.canvasState.scale;
              if (port.relativePosition.dx < port.parent.size.width * 0.1) {
                resultedPosition = transformedPos + Offset(-width - padding, 0);
              } else if (port.relativePosition.dx >
                  port.parent.size.width * 0.7) {
                resultedPosition = transformedPos + Offset(padding, 0);
              }
              overlay = OverlayContainer(
                position: resultedPosition,
                tipPosition: transformedPos,
                width: width,
                child: PortConnectionOverlay(
                  port: port,
                  componentDB: controller.componentDB,
                  controller: controller,
                ),
              );
            }
          }
          return FusionKeyboardWrapper(
            onUndo: () {
              controller.undo();
            },
            onRedo: () {
              controller.redo();
            },
            child: CanvasControlWrapper(
              circuitPainter: circuitPainter,
              controller: controller,
              child: Container(
                color: context.colorScheme.canvasBG,
                child: Stack(
                  children: <Widget>[
                    CustomPaint(
                      size: Size.infinite,
                      painter: circuitPainter,
                    ),
                    if (overlay != null) overlay,

                    Row(
                      children: <Widget>[
                        if (controller.stack.canUndo)
                          IconButton(
                            onPressed: () {
                              controller.undo();
                            },
                            icon: const Icon(Icons.undo),
                          ),
                        if (controller.stack.canRedo)
                          IconButton(
                            onPressed: () {
                              controller.redo();
                            },
                            icon: const Icon(Icons.redo),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
