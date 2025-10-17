import 'package:fusion_launcher/features/wiring_design/controller/circuit_controller.dart';
import 'package:fusion_launcher/features/wiring_design/model/circuit_port.dart';

extension ConnectionMethodsExtension on CircuitController {
  // List<CircuitPort> getPossiblePorts(CircuitPort port) {

  // }

  bool canHaveConnection(CircuitPort a, CircuitPort b) {
    return a.data.compatibleTypes.contains(b.data.type) &&
        b.data.compatibleTypes.contains(a.data.type);
  }
}
