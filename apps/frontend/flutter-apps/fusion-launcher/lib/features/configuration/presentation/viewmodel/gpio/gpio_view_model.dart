import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension GpioViewModel on ProjectViewModel {
  void addGPIOConfig({required GpioConfig config, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addGPIOConfig(config);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Add GPIO Config Error  ${e.toString()}");
    }
  }

  void updateGPIOConfig({required GpioConfig config, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateGPIOConfig(config);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Update GPIO Config Error  ${e.toString()}");
    }
  }

  void removeGPIOConfig({required String gpioConfigId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeGPIOConfig(gpioConfigId);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Delete GPIO Config Error  ${e.toString()}");
    }
  }

  List<GpioConfig> getAllGPIOConfigs() {
    try {
      return projectManager.getAllGPIOConfigs();
    } catch (e) {
      throwError("Get All GPIO Configs Error  ${e.toString()}");
      return <GpioConfig>[];
    }
  }

  List<GpioConfig> getGpiConfigs() {
    try {
      return projectManager.getGpiConfigs();
    } catch (e) {
      throwError("Get GPI Configs Error  ${e.toString()}");
      return <GpioConfig>[];
    }
  }

  List<GpioConfig> getGpoConfigs() {
    try {
      return projectManager.getGpoConfigs();
    } catch (e) {
      throwError("Get GPO Configs Error  ${e.toString()}");
      return <GpioConfig>[];
    }
  }

  List<GpiAction> getGPIActions() {
    try {
      return projectManager.getGPIActions();
    } catch (e) {
      throwError("Get GPI Actions Error  ${e.toString()}");
      return <GpiAction>[];
    }
  }

  List<GpoAction> getGPOActions() {
    try {
      return projectManager.getGPOActions();
    } catch (e) {
      throwError("Get GPO Actions Error  ${e.toString()}");
      return <GpoAction>[];
    }
  }

  int getAvailableGpioPorts() {
    try {
      return projectManager.getAvailableGpioPorts();
    } catch (e) {
      throwError("Get Available GPIO Ports Error  ${e.toString()}");
      return 0;
    }
  }

  int getTotalGpioPorts() {
    try {
      return projectManager.getTotalGpioPorts();
    } catch (e) {
      throwError("Get Total GPIO Ports Error  ${e.toString()}");
      return 0;
    }
  }
}
