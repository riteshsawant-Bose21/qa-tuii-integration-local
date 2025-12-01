import 'package:fusion_lib/fusion_lib.dart';

extension GpioService on ProjectService {
  void addGPIOConfig(GpioConfig config) {
    gpioConfigs.add(config.id, config);
  }

  void updateGPIOConfig(GpioConfig config) {
    if (!gpioConfigs.exists(config.id)) {
      throw Exception("GPIO Pin with ID ${config.id} does not exist.");
    }
    gpioConfigs.add(config.id, config);
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
}
