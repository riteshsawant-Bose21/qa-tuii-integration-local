import 'package:fusion_launcher/features/wiring_design/dto/component_data.dart';
import 'package:fusion_launcher/features/wiring_design/model/canvas_element.dart';
import 'package:fusion_launcher/features/wiring_design/model/circuit_component.dart';

import '../model/wire.dart';

class ComponentDb {
  final Map<String, CanvasElement> _mapping = <String, CanvasElement>{};
  final Map<String, ComponentData> _dataMapping = <String, ComponentData>{};

  // final Map<String, String> _parentMapping = <String, String>{};
  void addComponent(CircuitComponent component) {
    _mapping[component.id] = component;
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
}
