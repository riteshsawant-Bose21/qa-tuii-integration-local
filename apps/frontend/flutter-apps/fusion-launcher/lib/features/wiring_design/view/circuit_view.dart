import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/wiring_design/controller/circuit_controller.dart';
import 'package:fusion_launcher/features/wiring_design/controller/helpers/wiring_stats_methods.dart';
import 'package:fusion_launcher/features/wiring_design/controller/state/wiring_state.dart';
import 'package:fusion_launcher/features/wiring_design/model/circuit_port.dart';
import 'package:fusion_launcher/features/wiring_design/util/color_util.dart';
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
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Consumer<CircuitController>(
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
                final ElementSelectionState selectionState = controller.state as ElementSelectionState;
                if (selectionState.element is CircuitPort) {
                  final CircuitPort port = selectionState.element as CircuitPort;
                  final Offset transformedPos = circuitPainter.transformPosition(
                    port.position,
                  );
                  Offset resultedPosition = transformedPos;
                  final double width = 250; //* controller.canvasScale;
                  final double padding = 30 * controller.canvasState.scale;
                  if (port.relativePosition.dx < port.parent.size.width * 0.1) {
                    resultedPosition = transformedPos + Offset(-width - padding, 0);
                  } else if (port.relativePosition.dx > port.parent.size.width * 0.7) {
                    resultedPosition = transformedPos + Offset(padding, 0);
                  }
                  final Rect currentViewPortRect = controller.canvasState.offset & (constraints.biggest);

                  overlay = OverlayContainer(
                    viewPort: currentViewPortRect,
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
                onDelete: () {
                  controller.deleteSelectedElement();
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

                      
                        ///************************************************************************************************************
                        ///
                        ///
                        /// Legends
                        ///
                        ///************************************************************************************************************
                        Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(0.0),
                              color: Colors.grey.shade100,
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: <BoxShadow>[
                                // BoxShadow(
                                //   color: Colors.black.withValues(alpha: 0.1),
                                //   blurRadius: 12.0,
                                //   offset: const Offset(0, 4),
                                //   spreadRadius: 0,
                                // ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 5,
                              children: <Widget>[
                                for (final ({Color color, String label}) legend in <({Color color, String label})>[
                                  (
                                    color: context.colorScheme.switchWireColor,
                                    label: "${controller.noOfSwitches} switch connections",
                                  ),
                                  (
                                    color: context.colorScheme.analogWireColor,
                                    label: "${controller.state.wires.length} analog connections",
                                  ),
                                ])
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: 12,
                                    children: <Widget>[
                                      Container(
                                        width: 30,
                                        height: 3,
                                        color: legend.color,
                                      ),
                                      Text(
                                        legend.label,
                                        style: context.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),

                        ///************************************************************************************************************
                        ///
                        ///
                        /// Bottom Tool Bar
                        ///
                        ///************************************************************************************************************
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            margin: const EdgeInsets.only(
                              bottom: 24.0,
                              right: 24.0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50.0),
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 12.0,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 15,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Tooltip(
                                  message: "Fit to viewport",
                                  child: InkWell(
                                    onTap: () {
                                      controller.fitToViewPort();
                                    },
                                    child: const Icon(
                                      Icons.fit_screen_rounded,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
