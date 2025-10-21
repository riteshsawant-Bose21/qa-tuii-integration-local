import 'package:fusion_lib/fusion_lib.dart';

extension CircuitService on ProjectService {
  void addCircuit(CircuitModel circuit) {
    if (circuits.exists(circuit.id)) {
      throw Exception('Circuit with id ${circuit.id} already exists');
    }

    circuits.add(circuit.id, circuit);
  }

  CircuitModel? getCircuitById(String id) {
    return circuits.get(id);
  }

  void removeCircuit(String circuitId) {
    if (!circuits.exists(circuitId)) {
      throw Exception('Circuit with id $circuitId does not exist');
    }

    //remove all the hardware in the circuit
    final hardwareIds = relationships.getChildren(RelationshipType.circuitHardware, circuitId);
    for (final hwId in hardwareIds) {
      // Remove relationship links
      relationships.removeAllRelationships(hwId);

      // Remove repo entry
      hardware.remove(hwId);
    }

    final wireConnections = relationships.getChildren(RelationshipType.wireConnection, circuitId);
    for (final connId in wireConnections) {
      removeWiringConnection(connId);
    }

    // Remove all relationships
    relationships.removeAllRelationships(circuitId);
    // Remove the circuit
    circuits.remove(circuitId);
  }

  void updateCircuit(CircuitModel circuit) {
    if (!circuits.exists(circuit.id)) {
      throw Exception('Circuit with id ${circuit.id} does not exist');
    }

    // Update the circuit
    circuits.add(circuit.id, circuit);
  }

  List<CircuitModel> getAllCircuits() {
    return circuits.getAll();
  }

  void addHardwareToCircuit(String hwId, String circuitId) {
    if (!circuits.exists(circuitId)) {
      throw Exception('Circuit $circuitId does not exist');
    }

    relationships.link(RelationshipType.circuitHardware, circuitId, hwId);
  }

  List<HardwareComponent> getHardwareForCircuit(String circuitId) {
    if (!circuits.exists(circuitId)) {
      throw Exception('Circuit with id $circuitId does not exist');
    }
    final hardwareIds = relationships.getChildren(RelationshipType.circuitHardware, circuitId);
    return hardwareIds.map((id) => hardware.get(id)).whereType<HardwareComponent>().toList();
  }

  //remove hardware from circuit
  void removeHardwareFromCircuit(String hwId, String circuitId) {
    if (!circuits.exists(circuitId)) {
      throw Exception('Circuit with id $circuitId does not exist');
    }
    if (!hardware.exists(hwId)) {
      throw Exception('Hardware with id $hwId does not exist');
    }
    relationships.unlink(RelationshipType.circuitHardware, circuitId, hwId);

    final hwIds = relationships.getChildren(RelationshipType.circuitHardware, circuitId);
    if (hwIds.isEmpty) {
      //remove circuit if no hardware left
      removeCircuit(circuitId);
    }
  }

  List<ListeningArea> getListeningAreasForCircuit(String circuitId) {
    if (!circuits.exists(circuitId)) {
      throw Exception('Circuit with id $circuitId does not exist');
    }

    //get circuit hardware and its unique listening areas
    final hardwareIds = relationships.getChildren(RelationshipType.circuitHardware, circuitId);
    final Set<String> listeningAreaIds = {};
    for (final hwId in hardwareIds) {
      final hw = hardware.get(hwId);
      if (hw == null) continue;
      if (hw.locationEntity.listeningAreaId != null) {
        if (!listeningAreaIds.contains(hw.locationEntity.listeningAreaId)) {
          listeningAreaIds.add(hw.locationEntity.listeningAreaId!);
        }
      }
    }
    return listeningAreaIds.map((id) => listeningAreas.get(id)).whereType<ListeningArea>().toList();
  }

  void reOderCircuitsInZone(String parentId, int oldIndex, int newIndex) {
    final circuitsInZone = relationships.getChildren(RelationshipType.zoneCircuits, parentId).toList();

    final item = circuitsInZone.removeAt(oldIndex);
    circuitsInZone.insert(newIndex, item);

    relationships.reOrder(RelationshipType.zoneCircuits, parentId, circuitsInZone);
  }
}
