import 'package:fusion_lib/fusion_lib.dart';

extension GpioService on ProjectService {
  void addGPIOConfig(GpioConfig config) {
    gpioConfigs.add(config.id, config);
  }

  void updateGPIOConfig(GpioConfig config) {
    if (!gpioConfigs.exists(config.id)) {
      throw Exception("GPIO Pin with ID ${config.id} does not exist.");
    }

    final updatedConfig = config.direction == GpioDirection.input ? config.removeGpoAction() : config.removeGpiAction();

    gpioConfigs.add(updatedConfig.id, updatedConfig);
  }

  List<GpiAction> getGPIActions() {
    return GpiAction.values;
  }

  List<GpoAction> getGPOActions() {
    return GpoAction.values;
  }

  void removeGPIOConfig(String gpioConfigId) {
    if (!gpioConfigs.exists(gpioConfigId)) {
      throw Exception("GPIO Pin with ID $gpioConfigId does not exist.");
    }
    gpioConfigs.remove(gpioConfigId);
  }

  List<GpioConfig> getAllGPIOConfigs() {
    return gpioConfigs.getAll();
  }

  List<GpioConfig> getGpiConfigs() {
    return gpioConfigs.getAll().where((config) => config.direction == GpioDirection.input).toList();
  }

  List<GpioConfig> getGpoConfigs() {
    return gpioConfigs.getAll().where((config) => config.direction == GpioDirection.output).toList();
  }

  int getAvailableGpioPorts() {
    final dspCount = hardware.getAll().whereType<FusionDsp>();
    final availablePins = dspCount.length * 4;
    final usedPins = gpioConfigs.getAll().length;

    return availablePins - usedPins;
  }

  int getTotalGpioPorts() {
    final dspCount = hardware.getAll().whereType<FusionDsp>();
    final totalPins = dspCount.length * 4;
    return totalPins;
  }
}
