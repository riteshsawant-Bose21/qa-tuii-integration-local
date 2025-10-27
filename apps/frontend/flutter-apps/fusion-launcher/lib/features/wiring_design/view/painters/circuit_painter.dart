import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/wiring_design/controller/circuit_controller.dart';
import 'package:fusion_launcher/features/wiring_design/controller/state/wiring_state.dart';
import 'package:fusion_launcher/features/wiring_design/model/model.dart';
import 'package:fusion_launcher/features/wiring_design/view/painters/base_painter.dart';
import 'package:fusion_launcher/features/wiring_design/view/painters/component_painter.dart';
import 'package:fusion_launcher/features/wiring_design/view/painters/wire_painter.dart';

import 'dotted_grid_painter.dart';
import 'intermediate_wire_painter.dart';

class CircuitPainter extends CustomPainter {
  CircuitPainter(this.controller, this.colorScheme);
  final CircuitController controller;
  final ColorScheme colorScheme;

  final List<BasePainter> painters = <BasePainter>[];
  @override
  void paint(Canvas canvas, Size size) {
    painters.clear();
    canvas.save();
    final Offset offset = controller.canvasState.offset;
    controller.canvasSize = size;
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(controller.canvasState.scale);

    ///
    ///
    /// Background Dotted grid
    ///
    DottedGridPainter(color: colorScheme.outlineVariant.withAlpha(125)).paint(
      canvas,
      size,
      offset,
      controller.canvasState.scale,
    );

    // Paint components
    for (final CircuitComponent component in controller.state.components) {
      final ComponentPainter componentPainter = ComponentPainter(
        component: component,
        controller: controller,
        colorScheme: colorScheme,
      );
      componentPainter.paint(canvas, size);
      painters.add(componentPainter);
    }

    // Paint wires
    for (final Wire wire in controller.state.wires) {
      final WirePainter wirePainter = WirePainter(
        wire: wire,
        controller: controller,
        colorScheme: colorScheme,
      );
      wirePainter.paint(canvas, size);
      painters.add(wirePainter);
    }

    if (controller.state is ConnectionProgressWiringState) {
      final ConnectionProgressWiringState state =
          (controller.state as ConnectionProgressWiringState);
      final IntermediateWirePainter intermediateWirePainter =
          IntermediateWirePainter(
            start: state.port,
            end: state.destination,
            controller: controller,
            joints: state.path,
            colorScheme: colorScheme,
          );
      intermediateWirePainter.paint(canvas, size);
    }

    canvas.restore();
  }

  CanvasElement? isHit(Offset position) {
    for (final BasePainter painter in painters) {
      final CanvasElement? hitElement = painter.isHit(position);
      if (hitElement != null) {
        return hitElement;
      }
    }
    return null;
  }

  Offset correctPosition(Offset position) {
    final Offset offset = controller.canvasState.offset;
    final double scale = controller.canvasState.scale;
    return (position - offset) / scale;
  }

  Offset transformPosition(Offset position) {
    final Offset offset = controller.canvasState.offset;
    final double scale = controller.canvasState.scale;
    return (position * scale) + offset;
  }

  @override
  bool shouldRepaint(covariant CircuitPainter oldDelegate) => true;
}
