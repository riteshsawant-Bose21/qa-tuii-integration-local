import 'package:fusion_launcher/features/wiring_design/controller/circuit_controller.dart';
import 'package:fusion_launcher/features/wiring_design/model/circuit_component.dart';
import 'package:fusion_launcher/features/wiring_design/model/circuit_port.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension WiringStatsMethods on CircuitController {
  int get noOfSwitches => state.components.fold(
    0,
    (int val, CircuitComponent componenet) =>
        val +
        componenet.otherPorts
            .where((CircuitPort e) => e.data.type.isEthernet)
            .length,
  );
}

extension EthernetPortTypeCheck on PortType {
  bool get isEthernet =>
      this == PortType.networkSwitchIn ||
      this == PortType.networkSwitchOut ||
      this == PortType.ethernet;
}
