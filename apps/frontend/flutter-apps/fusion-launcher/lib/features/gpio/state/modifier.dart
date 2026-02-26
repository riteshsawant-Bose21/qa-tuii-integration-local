part of 'gpio_state.dart';


extension GpioStateMethods on GpioState {
  GpioState load({
    List<GpioConfig>? gpios,
    int? totalGPIOPorts,
    int? availableGPIOPorts,
  }) {
    return GpioState(
      gpios: gpios ?? this.gpios,
      totalGPIOPorts: totalGPIOPorts ?? this.totalGPIOPorts,
      availableGPIOPorts: availableGPIOPorts ?? this.availableGPIOPorts,
    );
  }



}