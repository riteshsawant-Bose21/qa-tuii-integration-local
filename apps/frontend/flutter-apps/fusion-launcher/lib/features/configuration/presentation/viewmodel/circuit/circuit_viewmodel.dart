import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension CircuitViewmodel on ProjectViewModel {
  void addNewCircuitWithHardware(HardwareComponent hardware) {
    try {
      final CircuitModel newCircuit = CircuitModel(
        id: FusionUtils.shortStringUUID(),
        name: "New Circuit",
      );
      addCircuit(newCircuit);
      addHardwareToCircuit(hardware.id, newCircuit.id);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add new circuit with hardware: $e");
      throwError("Failed to add new circuit with hardware: $e");
    }
  }

  void addCircuit(CircuitModel circuit) {
    try {
      projectManager.addCircuit(circuit);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add circuit: $e");
      throwError("Failed to add circuit: $e");
    }
  }

  void updateCircuit(CircuitModel circuit) {
    try {
      projectManager.updateCircuit(circuit);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update circuit: $e");
      throwError("Failed to update circuit: $e");
    }
  }

  void removeCircuit(String circuitId) {
    try {
      projectManager.removeCircuit(circuitId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove circuit: $e");
      throwError("Failed to remove circuit: $e");
    }
  }

  CircuitModel? getCircuitById(String circuitId) {
    try {
      return projectManager.getCircuitById(circuitId);
    } catch (e) {
      return null;
    }
  }

  List<CircuitModel> getAllCircuits() {
    try {
      return projectManager.getAllCircuits();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get all circuits: $e");
      throwError("Failed to get all circuits: $e");
      return <CircuitModel>[];
    }
  }

  List<HardwareComponent> getHardwareForCircuit(String circuitId) {
    try {
      return projectManager.getHardwareForCircuit(circuitId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get hardware for circuit: $e");
      throwError("Failed to get hardware for circuit: $e");
      return <HardwareComponent>[];
    }
  }

  void addHardwareToCircuit(String hwId, String circuitId) {
    try {
      projectManager.addHardwareToCircuit(hwId, circuitId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add hardware to circuit: $e");
      throwError("Failed to add hardware to circuit: $e");
    }
  }

  void removeHardwareFromCircuit(String hwId, String circuitId) {
    try {
      projectManager.removeHardwareFromCircuit(hwId, circuitId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove hardware from circuit: $e");
      throwError("Failed to remove hardware from circuit: $e");
    }
  }

  void removeAllCircuits() {
    try {
      final List<CircuitModel> allCircuits = getAllCircuits();
      for (final CircuitModel circuit in allCircuits) {
        projectManager.removeCircuit(circuit.id);
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove all circuits: $e");
      throwError("Failed to remove all circuits: $e");
    }
  }
}
