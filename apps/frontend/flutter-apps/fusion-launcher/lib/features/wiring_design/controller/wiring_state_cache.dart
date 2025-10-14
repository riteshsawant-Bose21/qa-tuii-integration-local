import 'package:fusion_launcher/features/wiring_design/controller/state/wiring_state.dart';

import '../model/circuit_component.dart';
import '../model/circuit_port.dart';
import '../model/wire.dart';

class WiringStateCache {
  final Map<CircuitComponent, List<Wire>> _componentWireCache =
      <CircuitComponent, List<Wire>>{};
  final Map<CircuitPort, List<Wire>> _portWireCache =
      <CircuitPort, List<Wire>>{};

  void cacheForState(WiringState state) {
    _componentWireCache.clear();
    _portWireCache.clear();

    for (final Wire wire in state.wires) {
      _componentWireCache[wire.from.parent] ??= <Wire>[];
      _componentWireCache[wire.from.parent]!.add(wire);
      _componentWireCache[wire.to.parent] ??= <Wire>[];
      _componentWireCache[wire.to.parent]!.add(wire);
      _portWireCache[wire.from] ??= <Wire>[];
      _portWireCache[wire.from]!.add(wire);
      _portWireCache[wire.to] ??= <Wire>[];
      _portWireCache[wire.to]!.add(wire);
    }
  }

  List<Wire> wiresOfComponent(CircuitComponent component) {
    return _componentWireCache[component] ?? <Wire>[];
  }

  List<Wire>? wireOfPort(CircuitPort port) {
    return _portWireCache[port];
  }
}
