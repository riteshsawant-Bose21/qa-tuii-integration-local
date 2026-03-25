import 'package:fusion_lib/fusion_lib.dart';

part 'modifier.dart';

class GpioState {
  final int totalGPIOPorts;
  final int availableGPIOPorts;
  final List<GpioConfig> gpios;

  GpioState({
    required this.totalGPIOPorts,
    required this.availableGPIOPorts,
    required this.gpios,
  });

  
}
