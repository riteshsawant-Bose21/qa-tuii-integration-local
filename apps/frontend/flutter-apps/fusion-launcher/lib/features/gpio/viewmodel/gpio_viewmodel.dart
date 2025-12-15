import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/gpio/gpio_view_model.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/models/project_entities/non_processing/gpio_config.dart';

import '../state/gpio_state.dart';

class GpioViewmodel extends Cubit<GpioState> {
  GpioViewmodel(this.projectViewModel) : super(GpioState(gpios: <GpioConfig>[], totalGPIOPorts: 0, availableGPIOPorts: 0)) {
    loadGpios();
  }
  final ProjectViewModel projectViewModel;

  void loadGpios() {
    final List<GpioConfig> gpios = projectViewModel.getAllGPIOConfigs();
    emit(
      state.load(
        gpios: gpios,
        totalGPIOPorts: projectViewModel.getTotalGpioPorts(),
        availableGPIOPorts: projectViewModel.getAvailableGpioPorts(),
      ),
    );
  }

  void refresh() {
    loadGpios();
  }

  void removeGpio(GpioConfig gpio) {
    projectViewModel.removeGPIOConfig(gpioConfigId: gpio.id);
  }

  void updateGpio(GpioConfig gpio) {
    projectViewModel.updateGPIOConfig(config: gpio);
  }
}
