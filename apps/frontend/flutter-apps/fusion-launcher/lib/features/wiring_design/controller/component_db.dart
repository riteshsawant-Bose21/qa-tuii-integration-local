import 'package:fusion_launcher/features/wiring_design/dto/component_data.dart';
import 'package:fusion_launcher/features/wiring_design/model/canvas_element.dart';
import 'package:fusion_launcher/features/wiring_design/model/circuit_component.dart';
import 'package:fusion_launcher/features/wiring_design/model/circuit_port.dart';

import '../model/wire.dart';

class ComponentDb {
  final Map<String, CanvasElement> _mapping = <String, CanvasElement>{};
  final Map<String, ComponentData> _dataMapping = <String, ComponentData>{};

  // final Map<String, String> _parentMapping = <String, String>{};
  void addComponent(CircuitComponent component) {
    _mapping[component.id] = component;
  }

  void addPort(CircuitPort port) {
    _mapping[port.id] = port;
  }

  void addWire(Wire wire) {
    _mapping[wire.id] = wire;
  }

  void addComponentData(ComponentData data) {
    _dataMapping[data.id] = data;
  }

  CanvasElement? getComponent(String id) {
    return _mapping[id];
  }

  Wire? getWire(String id) {
    final CanvasElement? element = _mapping[id];
    if (element is Wire) {
      return element;
    }
    return null;
  }

  CircuitPort? getPort(String id) {
    final CanvasElement? element = _mapping[id];
    if (element is CircuitPort) {
      return element;
    }
    return null;
  }

  ComponentData? getComponentData(String id) {
    return _dataMapping[id];
  }


  List<CircuitComponent> getAllComponents() {
    return _mapping.values
        .whereType<CircuitComponent>()
        .toList(growable: false);
  }
}
