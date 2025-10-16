import 'dart:math';
import 'dart:ui';

import 'package:fusion_launcher/features/wiring_design/dto/component_data.dart';
import 'package:fusion_launcher/features/wiring_design/util/wiring_serialization_util.dart';

import '../util/canvas_util.dart';
import 'canvas_element.dart';
import 'circuit_port.dart';

class CircuitComponent extends CanvasElement {
  @override
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

  List<CircuitPort> get ports => <CircuitPort>[
    ...inputPorts,
    ...outputPorts,
    ...otherPorts,
  ];
  final List<CircuitPort> inputPorts = <CircuitPort>[];
  final List<CircuitPort> outputPorts = <CircuitPort>[];
  final List<CircuitPort> otherPorts = <CircuitPort>[];

  CircuitComponent? parent;
  final List<CircuitComponent> children = <CircuitComponent>[];

  final ComponentData data;
  CircuitComponent({
    required this.id,
    required Offset position,
    // required this.ports,
    required this.data,
    this.parent,
  }) : _position = position;

  static CircuitComponent from(ComponentData data, CircuitComponent? parent) {
    final Size size = data.size;
    final CircuitComponent circuitComponent = CircuitComponent(
      id: data.id,
      position:
          (parent?.position ?? Offset.zero) +
          Offset(
            10,
            parent?.size.height ?? 0,
          ), //Offset(100, 100.0 * index),
      // ports: ports,
      data: data,
    );

    ///
    /// For Left Side
    ///
    for (int i = 0; i < data.inputPorts.length; i++) {
      final ComponentPort element = data.inputPorts[i];
      circuitComponent.addInputPort(
        CircuitPort(
          id: "${data.id}_input_$i",
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
      final ComponentPort element = data.outputPorts[i];
      circuitComponent.addOutputPort(
        CircuitPort(
          id: "${data.id}_output_$i",
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
    final double currentHeight = circuitComponent.ports.fold(
      0.0,
      (double a, CircuitPort b) => max(a, b.relativePosition.dy),
    );

    // /// For Other Ports
    // for (int i = 0; i < data.comPorts.length; i++) {
    //   final ComponentPort element = data.comPorts[i];

    //   circuitComponent.addOtherPort(
    //     CircuitPort(
    //       id: "${data.id}_other_$i",
    //       relativePosition: Offset(
    //         data.portRadius +
    //             data.portOffset.dy +
    //             (WiringViewConstants.portSpacing * (i + 1)) +
    //             i * data.portRadius * 2,
    //         size.height - data.portRadius - WiringViewConstants.portSpacing,
    //       ),
    //       padding: Offset(50 + i * 10, 0),
    //       parent: circuitComponent,
    //       data: element,
    //     ),
    //   );
    // }
    final List<ComponentPort> leftSidePorts =
        data.comPorts
            .where(
              (ComponentPort e) => e.position == PortPosition.bottomLeft,
            )
            .toList()
          ..sort(
            (ComponentPort a, ComponentPort b) => a.index.compareTo(b.index),
          );
    final List<ComponentPort> rightSidePorts =
        data.comPorts
            .where(
              (ComponentPort e) => e.position == PortPosition.bottomRight,
            )
            .toList()
          ..sort(
            (ComponentPort a, ComponentPort b) => a.index.compareTo(b.index),
          );
    final List<ComponentPort> footerLeft =
        data.comPorts
            .where(
              (ComponentPort e) => e.position == PortPosition.footerLeft,
            )
            .toList()
          ..sort(
            (ComponentPort a, ComponentPort b) => a.index.compareTo(b.index),
          );
    final List<ComponentPort> footerCenter =
        data.comPorts
            .where(
              (ComponentPort e) =>
                  e.position == PortPosition.footerCenter || e.position == null,
            )
            .toList()
          ..sort(
            (ComponentPort a, ComponentPort b) => a.index.compareTo(b.index),
          );
    final List<ComponentPort> footerRight =
        data.comPorts
            .where(
              (ComponentPort e) => e.position == PortPosition.footerRight,
            )
            .toList()
          ..sort(
            (ComponentPort a, ComponentPort b) => a.index.compareTo(b.index),
          );

    for (int i = 0; i < leftSidePorts.length; i++) {
      final ComponentPort element = leftSidePorts[i];

      circuitComponent.addOtherPort(
        CircuitPort(
          id: "${data.id}_other_$i",
          relativePosition: Offset(
            data.portRadius + WiringViewConstants.portSpacing,
            currentHeight +
                data.portOffset.dy +
                data.portRadius +
                (WiringViewConstants.portSpacing * (i + 1)) +
                i * data.portRadius * 2,
          ),
          padding: Offset(50 + i * 10, 0),
          parent: circuitComponent,
          data: element,
        ),
      );
    }
    for (int i = 0; i < rightSidePorts.length; i++) {
      final ComponentPort element = rightSidePorts[i];

      circuitComponent.addOtherPort(
        CircuitPort(
          id: "${data.id}_other_$i",
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

  void addInputPort(CircuitPort port) {
    inputPorts.add(port);
  }

  void addOutputPort(CircuitPort port) {
    outputPorts.add(port);
  }

  void addOtherPort(CircuitPort port) {
    otherPorts.add(port);
  }

  CanvasElement? isHit(Offset position) {
    for (final CircuitPort port in ports) {
      final Rect portRect = Rect.fromCircle(
        center: port.position,
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

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'position': <String, double>{
        "x": _position.dx,
        "y": _position.dy,
      },
      'parent': parent?.id,
      'children': children.map((CircuitComponent e) => e.id).toList(),
      'data': data.id,
      'input_ports': inputPorts.map((CircuitPort e) => e.id).toList(),
      'output_ports': outputPorts.map((CircuitPort e) => e.id).toList(),
      'other_ports': otherPorts.map((CircuitPort e) => e.id).toList(),
    };
  }

  @override
  void restoreFromMap(Map<dynamic, dynamic> map) {
    _position =
        WiringSerializationUtil.offsetDeserializer.deserialize(
          map['position'],
        ) ??
        _position;
  }
}
