import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/project_manger/circuit/circuit_service.dart';

extension CircuitManager on ProjectManager {
  CircuitModel? getCircuitById(String id) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getCircuitById(id);
  }

  void addCircuit(CircuitModel circuit) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addCircuit(circuit);
  }

  void removeCircuit(String circuitId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeCircuit(circuitId);
  }

  void updateCircuit(CircuitModel circuit) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateCircuit(circuit);
  }

  List<CircuitModel> getAllCircuits() {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getAllCircuits();
  }

  List<HardwareComponent> getHardwareForCircuit(String circuitId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getHardwareForCircuit(circuitId);
  }

  void removeHardwareFromCircuit(String circuitId, String hardwareId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeHardwareFromCircuit(circuitId, hardwareId);
  }

  void addHardwareToCircuit(
    String hardwareId,
    String circuitId,
  ) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addHardwareToCircuit(hardwareId, circuitId);
  }
}
