import 'dart:ui';

import 'package:fusion_launcher/features/wiring_design/dto/component_data.dart';

import '../util/canvas_util.dart';
import 'canvas_element.dart';
import 'circuit_port.dart';

class CircuitComponent extends CanvasElement {
  final String id;
  @override
  Offset position; // Top-left corner
  @override
  Size size;
  final List<CircuitPort> ports;

  final ComponentData data;
  CircuitComponent({
    required this.id,
    required this.position,
    required this.size,
    required this.ports,
    required this.data,
  });

  static CircuitComponent from(ComponentData data, int index) {
    final List<CircuitPort> ports = <CircuitPort>[];

    final Size size = data.size;
    final CircuitComponent circuitComponent = CircuitComponent(
      id: "_$index",
      position: Offset(100, 100.0 * index),
      size: size,
      ports: ports,
      data: data,
    );

    ///
    /// For Left Side
    ///
    for (int i = 0; i < data.inputPorts.length; i++) {
      final InputComponentPort element = data.inputPorts[i];
      ports.add(
        CircuitPort(
          id: "input_$i",
          relativePosition: Offset(
            data.portRadius + WiringViewConstants.portSpacing,
            data.portRadius +
                data.portOffset.dy +
                (WiringViewConstants.portSpacing * (i + 1)) +
                i * data.portRadius * 2,
          ),
          padding: Offset(-50 - i * 10, 0),
          parent: circuitComponent,
          data: element,
        ),
      );
    }

    /// For Right Side
    for (int i = 0; i < data.outputPorts.length; i++) {
      final OutputComponentPort element = data.outputPorts[i];
      ports.add(
        CircuitPort(
          id: "output_$i",
          relativePosition: Offset(
            size.width - data.portRadius - WiringViewConstants.portSpacing,
            data.portRadius +
                data.portOffset.dy +
                (WiringViewConstants.portSpacing * (i + 1)) +
                i * data.portRadius * 2,
          ),
          padding: Offset(50 + i * 10, 0),
          parent: circuitComponent,
          data: element,
        ),
      );
    }

    return circuitComponent;
  }
}
