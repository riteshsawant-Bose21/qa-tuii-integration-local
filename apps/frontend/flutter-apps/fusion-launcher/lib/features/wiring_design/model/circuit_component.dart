import 'dart:math';
import 'dart:ui';

import 'package:fusion_launcher/features/wiring_design/dto/component_data.dart';

import '../util/canvas_util.dart';
import 'canvas_element.dart';
import 'circuit_port.dart';

class CircuitComponent extends CanvasElement {
  final String id;
  Offset _position;

  @override
  Offset get position => (parent?.position ?? Offset.zero) + _position;

  void changePosition(Offset offset) {
    if (parent != null) {
      parent!.changePosition(offset);
    } else {
      _position += offset;
    }
  }

  // set position(Offset value) {
  //   _position = value;
  // } // Top-left corner
  @override
  Size get size {
    if (children.isEmpty) return data.size;

    num maxWidth = data.size.width;
    num maxHight = data.size.height;

    for (final CircuitComponent child in children) {
      maxWidth = max(maxWidth, child.size.width);
      maxHight += child.size.height + 30;
    }
    return Size(maxWidth.toDouble(), maxHight.toDouble());
  }

  CanvasElement? isHit(Offset position) {
    for (final CircuitPort port in ports) {
      final Rect portRect = Rect.fromCircle(
        center: this.position + port.relativePosition,
        radius: WiringViewConstants.portRadius,
      );
      if (portRect.contains(position)) {
        return port;
      }
    }
    for (final CircuitComponent child in children) {
      final CanvasElement? val = child.isHit(position);
      if (val != null) return val;
    }
    final Rect rect = this.position & size;
    if (rect.contains(position)) {
      return this;
    }
    return null;
  }

  final List<CircuitPort> ports;

  CircuitComponent? parent;
  final List<CircuitComponent> children = <CircuitComponent>[];

  final ComponentData data;
  CircuitComponent({
    required this.id,
    required Offset position,
    required this.ports,
    required this.data,
    this.parent,
  }) : _position = position;

  static CircuitComponent from(ComponentData data, CircuitComponent? parent) {
    final List<CircuitPort> ports = <CircuitPort>[];

    final Size size = data.size;
    final CircuitComponent circuitComponent = CircuitComponent(
      id: data.id,
      position:
          (parent?.position ?? Offset.zero) +
          Offset(
            10,
            parent?.size.height ?? 0,
          ), //Offset(100, 100.0 * index),
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
