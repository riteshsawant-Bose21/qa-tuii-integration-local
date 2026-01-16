import 'package:fusion_lib/fusion_lib.dart';

extension GpioManager on ProjectManager {
  void addGPIOConfig(GpioConfig config) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.addGPIOConfig(config);
  }

  void updateGPIOConfig(GpioConfig config) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.updateGPIOConfig(config);
  }

  List<GpiAction> getGPIActions() {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    return projectService!.getGPIActions();
  }

  List<GpoAction> getGPOActions() {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    return projectService!.getGPOActions();
  }

  void removeGPIOConfig(String gpioConfigId) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.removeGPIOConfig(gpioConfigId);
  }

  List<GpioConfig> getAllGPIOConfigs() {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    return projectService!.getAllGPIOConfigs();
  }

  List<GpioConfig> getGpiConfigs() {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    return projectService!.getGpiConfigs();
  }

  List<GpioConfig> getGpoConfigs() {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    return projectService!.getGpoConfigs();
  }

  int getAvailableGpioPorts() {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    return projectService!.getAvailableGpioPorts();
  }

  int getTotalGpioPorts() {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    return projectService!.getTotalGpioPorts();
  }

  void reOrderGpio({required String gpioIdToMove, required String gpioAtNewIndexId}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    Map<String, GpioConfig> reorderedList = projectService!.reOrderGpio(
      gpioIdToMove: gpioIdToMove,
      gpioAtNewIndexId: gpioAtNewIndexId,
    );
    projectService = projectService!.copyWith(
      gpioRepository: projectService!.gpioConfigs.copyWith(reorderedList),
    );
  }
}
