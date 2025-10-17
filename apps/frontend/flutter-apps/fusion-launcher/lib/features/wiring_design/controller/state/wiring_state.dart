import 'dart:ui';

import 'package:fusion_launcher/features/wiring_design/controller/component_db.dart';
import 'package:fusion_launcher/features/wiring_design/controller/state/canvas_state.dart';
import 'package:fusion_launcher/features/wiring_design/model/canvas_element.dart';
import 'package:fusion_launcher/features/wiring_design/model/circuit_component.dart';
import 'package:fusion_launcher/features/wiring_design/model/circuit_port.dart';
import 'package:fusion_launcher/features/wiring_design/util/wiring_serialization_util.dart';

import '../../model/wire.dart';

abstract class WiringState {
  final List<CircuitComponent> components;
  final List<Wire> wires;

  final CanvasState canvasState;

  WiringState({
    required this.components,
    required this.wires,
    required this.canvasState,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'components': components.map((CircuitComponent e) => e.toMap()).toList(),
      'wires': wires.map((Wire e) => e.toMap()).toList(),
    };
  }

  WiringState fromMap({
    required Map<dynamic, dynamic> map,
    required ComponentDb db,
  }) {
    final List<CircuitComponent> components = <CircuitComponent>[];
    final List<Wire> wires = <Wire>[];
    for (final dynamic element in map['components']) {
      if (element is Map) {
        final String? id = WiringSerializationUtil.stringDeserializer
            .deserialize(
              element['id'],
            );
        if (id == null) continue;
        final CanvasElement? comp = db.getComponent(id);
        if (comp == null) continue;
        if (comp is! CircuitComponent) continue;
        comp.restoreFromMap(element);
        components.add(comp);
      }
    }

    for (final dynamic element in map['wires']) {
      if (element is Map) {
        final String? id = WiringSerializationUtil.stringDeserializer
            .deserialize(
              element['id'],
            );
        if (id == null) continue;
        final CanvasElement? comp = db.getComponent(id);
        if (comp == null) continue;
        if (comp is! Wire) continue;
        comp.restoreFromMap(element);
        wires.add(comp);
      }
    }

    return IdleWiringState(
      components: components,
      wires: wires,
      canvasState: canvasState,
    );
  }
}

class IdleWiringState extends WiringState {
  IdleWiringState({
    required super.components,
    required super.wires,
    required super.canvasState,
  });
}

class ElementSelectionState extends WiringState {
  final CanvasElement element;
  ElementSelectionState({
    required this.element,
    required super.components,
    required super.wires,
    required super.canvasState,
  });
}

class ElementMovingState extends WiringState {
  final CircuitComponent element;
  final Offset position;
  ElementMovingState({
    required super.components,
    required super.wires,
    required super.canvasState,
    required this.element,
    required this.position,
  });
}

class ConnectionProgressWiringState extends WiringState {
  final CircuitPort port;
  final Offset destination;
  final List<Offset> path;
  ConnectionProgressWiringState({
    required super.components,
    required super.wires,
    required this.port,
    required super.canvasState,
    required this.destination,
    required this.path,
  });
}

extension WiringStateMutation on WiringState {
  ElementSelectionState addWire(Wire wire) {
    return ElementSelectionState(
      components: components,
      wires: <Wire>[...wires, wire],
      canvasState: canvasState,
      element: wire,
    );
  }

  IdleWiringState addComponent(CircuitComponent component) {
    return IdleWiringState(
      components: <CircuitComponent>[...components, component],
      wires: <Wire>[...wires],
      canvasState: canvasState,
    );
  }

  IdleWiringState updateCanvasState(CanvasState newCanvasState) {
    return IdleWiringState(
      components: components,
      wires: wires,
      canvasState: newCanvasState,
    );
  }

  ElementSelectionState select(CanvasElement element) {
    return ElementSelectionState(
      element: element,
      components: components,
      wires: wires,
      canvasState: canvasState,
    );
  }

  WiringState startMoving(CanvasElement element, Offset position) {
    if (element is CircuitPort) {
      return ConnectionProgressWiringState(
        components: components,
        wires: wires,
        port: element,
        canvasState: canvasState,
        destination: position,
        path: <Offset>[],
      );
    }
    if (element is CircuitComponent) {
      return ElementMovingState(
        components: components,
        wires: wires,
        canvasState: canvasState,
        element: element,
        position: position,
      );
    }

    return ElementSelectionState(
      element: element,
      components: components,
      wires: wires,
      canvasState: canvasState,
    );
  }

  IdleWiringState idle() {
    return IdleWiringState(
      components: components,
      wires: wires,
      canvasState: canvasState,
    );
  }
}

extension WiringConnectionMutation on ConnectionProgressWiringState {
  ConnectionProgressWiringState moveTo(Offset offset, List<Offset> path) {
    return ConnectionProgressWiringState(
      components: components,
      wires: wires,
      port: port,
      canvasState: canvasState,
      destination: offset,
      path: path,
    );
  }
}

extension ElementMovingMutation on ElementMovingState {
  ElementMovingState move(Offset delta) {
    (element).changePosition(delta);
    return ElementMovingState(
      components: components,
      wires: wires,
      canvasState: canvasState,
      element: element,
      position: position + delta,
    );
  }
}
