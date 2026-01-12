import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/product_port_data.dart';

import '../project_view_model.dart';

extension ProductViewModel on ProjectViewModel {
  HardwareComponent assignPortData({
    required HardwareComponent hardware,
    required ProductType type,
    required ProductPortData portData,
    required String modelFamily,
  }) {
    hardware.inputPortsData.clear();
    hardware.outputPortsData.clear();
    hardware.communicationPorts.clear();
    hardware.inputPortsData.addAll(
      portData.getInputPorts(type, modelFamily.toLowerCase().contains("powersmart")),
    );
    hardware.outputPortsData.addAll(portData.getOutputPorts(type));
    hardware.communicationPorts.addAll(portData.comPorts);
    return hardware;
  }
}
