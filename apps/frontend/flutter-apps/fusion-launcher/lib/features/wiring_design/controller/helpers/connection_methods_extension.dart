import 'package:fusion_launcher/features/wiring_design/controller/circuit_controller.dart';
import 'package:fusion_launcher/features/wiring_design/model/circuit_port.dart';

extension ConnectionMethodsExtension on CircuitController {
  // List<CircuitPort> getPossiblePorts(CircuitPort port) {

  // }

  bool canHaveConnection(CircuitPort a, CircuitPort b) {
    return a.canConnect(b);
  }
}

extension ConnectionHelperExtension on CircuitPort {
  bool canConnect(CircuitPort otherPort) {
    return data.compatibleTypes.contains(otherPort.data.type) &&
        otherPort.data.compatibleTypes.contains(data.type);
  }
}
