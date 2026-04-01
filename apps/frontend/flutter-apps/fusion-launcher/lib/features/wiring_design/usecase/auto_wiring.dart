import 'package:fusion_launcher/features/wiring_design/usecase/connection_usecase.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Automatically creates wiring suggestions between compatible ports.
///
/// Why this use case exists:
/// - It reduces manual wiring effort by proposing valid connections.
/// - It prevents duplicate connections by checking both existing and newly
///   created links during a run.
/// - It centralizes compatibility logic so wiring behavior stays consistent.
///
/// How it works:
/// - For each eligible port, it finds the first compatible and free target port.
/// - Compatibility is currently based on `PortData.compatibleTypes` and `type`.
/// - `Speaker` and `HardwareRack` components are intentionally skipped.
///
/// The algorithm is greedy (first-match wins), so result ordering depends on
/// the order of [components], [circuits], and each component's port lists.
///
/// Example:
/// ```dart
/// final AutoWiringUseCase autoWiringUseCase = AutoWiringUseCase();
///
/// final List<WiringConnectionModel> suggestions = autoWiringUseCase.autoWire(
///   components: components,
///   circuits: circuits,
///   existingConnections: existingConnections,
/// );
///
/// // Persist or apply suggestions to your state as needed.
/// final List<WiringConnectionModel> updatedConnections = <WiringConnectionModel>[
///   ...existingConnections,
///   ...suggestions,
/// ];
/// ```
class AutoWiringUseCase {
  /// Auto-wires a single hardware component to compatible targets.
  ///
  /// Use this when one device changes (for example after drag/drop or a port
  /// update) and you only want incremental wiring suggestions for that device.
  List<WiringConnectionModel> autoWireForHardware({
    required HardwareComponent component,
    required List<HardwareComponent> allComponents,
    required List<CircuitModel> circuits,
    required List<WiringConnectionModel> existingConnections,
  }) {
    final List<WiringConnectionModel> newConnections = <WiringConnectionModel>[];

    if (component is Speaker || component is HardwareRack) {
      return newConnections;
    }

    for (final PortData port in <PortData>[...component.inputPortsData, ...component.outputPortsData, ...component.communicationPorts]) {
      final List<WiringConnectionModel> allConnections = <WiringConnectionModel>[...existingConnections, ...newConnections];
      if (_hasExistingConnection(component.id, port.id, allConnections)) {
        continue;
      }

      final (String, PortData)? bestMatch = _findBestPortMatch(
        component.id,
        port,
        allComponents,
        circuits,
        allConnections,
      );

      if (bestMatch != null) {
        final String targetComponentId = bestMatch.$1;
        final PortData targetPort = bestMatch.$2;

        newConnections.add(
          _createConnection(
            fromDeviceId: component.id,
            fromPort: port,
            toDeviceId: targetComponentId,
            toPort: targetPort,
          ),
        );
      }
    }

    return newConnections;
  }

  /// Auto-wires a single circuit input port to a compatible source.
  ///
  /// Use this when you want suggestions scoped to one circuit instead of
  /// running full-project auto wiring.
  List<WiringConnectionModel> autoWireForCircuit({
    required CircuitModel circuit,
    required List<HardwareComponent> allComponents,
    required List<CircuitModel> circuits,
    required List<WiringConnectionModel> existingConnections,
  }) {
    final List<WiringConnectionModel> newConnections = <WiringConnectionModel>[];

    final PortData port = circuit.inputPort;
    final List<WiringConnectionModel> allConnections = <WiringConnectionModel>[...existingConnections];
    if (_hasExistingConnection(circuit.id, port.id, allConnections)) {
      return newConnections;
    }

    final (String, PortData)? bestMatch = _findBestPortMatch(
      circuit.id,
      port,
      allComponents,
      circuits,
      allConnections,
    );

    if (bestMatch != null) {
      final String targetComponentId = bestMatch.$1;
      final PortData targetPort = bestMatch.$2;
      newConnections.add(
        _createConnection(
          fromDeviceId: circuit.id,
          fromPort: port,
          toDeviceId: targetComponentId,
          toPort: targetPort,
        ),
      );
    }

    return newConnections;
  }

  /// Auto-wires all provided components, then all circuits.
  ///
  /// This is the primary entry point for generating connection suggestions for
  /// the whole canvas. Newly created links are included immediately in the
  /// running connection set, which avoids duplicate links within the same pass.
  List<WiringConnectionModel> autoWire({
    required List<HardwareComponent> components,
    required List<CircuitModel> circuits,
    required List<WiringConnectionModel> existingConnections,
  }) {
    final List<WiringConnectionModel> newConnections = <WiringConnectionModel>[];

    for (final HardwareComponent component in components) {
      newConnections.addAll(
        autoWireForHardware(
          component: component,
          allComponents: components,
          circuits: circuits,
          existingConnections: <WiringConnectionModel>[...existingConnections, ...newConnections],
        ),
      );
    }
    for (final CircuitModel circuit in circuits) {
      newConnections.addAll(
        autoWireForCircuit(
          circuit: circuit,
          allComponents: components,
          circuits: circuits,
          existingConnections: <WiringConnectionModel>[...existingConnections, ...newConnections],
        ),
      );
    }

    return newConnections;
  }

  /// Finds the first compatible, currently unconnected target port.
  ///
  /// Search order:
  /// 1. Other hardware components (excluding `Speaker` and `HardwareRack`)
  /// 2. Circuit input ports
  (String, PortData)? _findBestPortMatch(
    String component,
    PortData port,
    List<HardwareComponent> allComponents,
    List<CircuitModel> circuits,
    List<WiringConnectionModel> existingConnections,
  ) {
    for (final HardwareComponent targetComponent in allComponents) {
      if (targetComponent is Speaker || targetComponent is HardwareRack) {
        continue; // Skip non-connectable components
      }
      if (targetComponent.id == component) {
        continue; // Skip self
      }

      final List<PortData> targetPorts = <PortData>[
        ...targetComponent.inputPortsData,
        ...targetComponent.outputPortsData,
        ...targetComponent.communicationPorts,
      ];

      for (final PortData targetPort in targetPorts) {
        if (_arePortsCompatible(port, targetPort) && !_hasExistingConnection(targetComponent.id, targetPort.id, existingConnections)) {
          return (targetComponent.id, targetPort);
        }
      }
    }

    for (final CircuitModel circuit in circuits) {
      final PortData circuitPort = circuit.inputPort;
      if (_arePortsCompatible(port, circuitPort) && !_hasExistingConnection(circuit.id, circuitPort.id, existingConnections)) {
        return (circuit.id, circuitPort);
      }
    }
    return null;
  }

  /// Returns `true` when either port declares the other port's type as
  /// compatible.
  bool _arePortsCompatible(PortData port1, PortData port2) {
    return ConnectionUseCase().isCompatible(port1.type, port2.type);
    // Additional compatibility logic can be added here (e.g., based on port names or other metadata)
  }

  /// Returns `true` when the given `deviceId` + `portId` is already used on
  /// either side of an existing connection.
  bool _hasExistingConnection(
    String deviceId,
    String portId,
    List<WiringConnectionModel> connections,
  ) {
    return connections.any(
      (WiringConnectionModel connection) =>
          (connection.deviceId == deviceId && connection.portId == portId) || (connection.targetDeviceId == deviceId && connection.targetPortId == portId),
    );
  }

  /// Delegates connection object creation to [ConnectionUseCase] so the
  /// connection shape/metadata stays consistent across the feature.
  WiringConnectionModel _createConnection({required String fromDeviceId, required PortData fromPort, required String toDeviceId, required PortData toPort}) {
    return ConnectionUseCase().createConnection(
      fromDeviceId: fromDeviceId,
      fromPort: fromPort,
      toDeviceId: toDeviceId,
      toPort: toPort,
    );
  }
}
