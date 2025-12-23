import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension EquipLocationViewModel on ProjectViewModel {
  List<EquipLocation> get equipLocations => projectManager.getAllEquipLocations();

  void addEquipLocation({required EquipLocation equipLocation, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addEquipLocation(equipLocation);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError('Failed to add EquipLocation: $e');
    }
  }

  void updateEquipLocation({required EquipLocation equipLocation, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateEquipLocation(equipLocation);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError('Failed to update EquipLocation: $e');
    }
  }

  void removeEquipLocation({required String equipLocationId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeEquipLocation(equipLocationId);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError('Failed to remove EquipLocation: $e');
    }
  }

  EquipLocation getEquipLocationById({required String equipLocationId}) {
    return projectManager.getEquipLocationById(equipLocationId);
  }

  void addHardwareToEquipLocation({required String hardwareId, required String equipLocationId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addHardwareToEquipLocation(hardwareId, equipLocationId);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError('Failed to add Hardware to EquipLocation: $e');
    }
  }

  void removeHardwareFromEquipLocation({required String hardwareId, required String equipLocationId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeHardwareFromEquipLocation(hardwareId, equipLocationId);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError('Failed to remove Hardware from EquipLocation: $e');
    }
  }

  List<HardwareComponent> getHardwareForEquipLocation({required String equipLocationId}) {
    try {
      return projectManager.getHardwareForEquipLocation(equipLocationId);
    } catch (e) {
      throwError('Failed to get Hardware for EquipLocation: $e');
      return <HardwareComponent>[];
    }
  }
}
