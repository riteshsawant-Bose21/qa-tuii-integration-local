import 'package:flutter/cupertino.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:fusion_lib/models/project_entities/endpoints.dart';

extension ProjectPropertiesViewModel on ProjectViewModel {
  List<Zone> get zones => projectManager.getAllZones();

  List<SubZone> get subZones => projectManager.getAllSubZones();

  List<FloorModel> get floors => projectManager.getAllFloors();

  List<HardwareComponent> get hardwareComponents => projectManager.getAllHardwareComponents();

  List<ListeningArea> get listeningAreas => projectManager.getAllListeningAreas();

  List<SourceSet> get sourceSets => projectManager.getAllSourceSets();

  List<CircuitModel> get circuits => projectManager.getAllCircuits();

  String get projectName => projectManager.getProjectName();

  String get projectId => projectManager.getProjectId();

  String? get virtualIP => projectManager.getVirtualIP();

  String get metaData => projectManager.getMetaData();

  double get minSPL => projectManager.getMinSPL();

  double get maxSPL => projectManager.getMaxSPL();

  bool get isInControlMode => projectManager.inControlMode();

  List<Color> get projectColors => projectManager.getProjectColors();

  bool get isAdminLogin => projectManager.isAdminLogin();

  int get currentFloorIndex => projectManager.getCurrentFloorIndex();

  //get sources by filtering only class type Source  in hardwareComponent
  List<Source> get sources {
    return hardwareComponents.whereType<Source>().toList();
  }

  // get Speakers
  List<Speaker> get speakers {
    return hardwareComponents.whereType<Speaker>().toList();
  }

  // get Amplifiers
  List<Amplifier> get amplifiers {
    return hardwareComponents.whereType<Amplifier>().toList();
  }

  // get Processors/DSPs
  List<FusionDsp> get fusionDsps {
    return hardwareComponents.whereType<FusionDsp>().toList();
  }

  List<FusionEndpoints> get fusionEndpoints {
    return hardwareComponents.whereType<FusionEndpoints>().toList();
  }

  List<FusionController> get fusionControllers {
    return hardwareComponents.whereType<FusionController>().toList();
  }

  List<NetworkSwitch> get networkSwitches {
    return hardwareComponents.whereType<NetworkSwitch>().toList();
  }

  List<HardwareRack> get hardwareRacks {
    return hardwareComponents.whereType<HardwareRack>().toList();
  }

  //get generic hardware components
  List<GenericHardwareComponent> get genericHardwareComponents {
    return hardwareComponents.whereType<GenericHardwareComponent>().toList();
  }

  //extend hardware component,
  //get all Fusion devices
  List<FusionDsp> get fusionDevices => projectManager.getAllFusionDevices();

  FloorModel get currentFloor {
    return floors[currentFloorIndex];
  }

  //set project name
  void setProjectName({required String name, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.setProjectName(name);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to set project name: $e");
      throwError("Failed to set project name: $e");
    }
  }

  //set virtual IP
  void setVirtualIP({required String? ip, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.setVirtualIP(ip);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to set virtual IP: $e");
      throwError("Failed to set virtual IP: $e");
    }
  }

  //set meta data
  void setMetaData({required String metaData, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.setMetaData(metaData);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to set meta data: $e");
      throwError("Failed to set meta data: $e");
    }
  }

  //set min SPL
  void setMinSPL({required double minSPL, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.setMinSPL(minSPL);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to set min SPL: $e");
      throwError("Failed to set min SPL: $e");
    }
  }

  //set max SPL
  void setMaxSPL({required double maxSPL, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.setMaxSPL(maxSPL);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to set max SPL: $e");
      throwError("Failed to set max SPL: $e");
    }
  }

  //set control mode
  void toggleControlMode({bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.toggleControlMode();
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to set control mode: $e");
      throwError("Failed to set control mode: $e");
    }
  }

  //set project colors
  void setProjectColors(List<Color> colors) {
    try {
      projectManager.setProjectColors(colors);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to set project colors: $e");
      throwError("Failed to set project colors: $e");
    }
  }

  //update current floor index
  void setCurrentFloorIndex(int index) {
    try {
      projectManager.setCurrentFloorIndex(index);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to set current floor index: $e");
      throwError("Failed to set current floor index: $e");
    }
  }

  void setCurrentSelectedHardware(String? hardware) {
    currentSelectedHardwareId = hardware;
    updateProject();
  }

  void setCurrentSelectedListeningArea(String? area) {
    currentSelectedListeningAreaId = area;
    updateProject();
  }

  HardwareComponent? getCurrentSelectedHardware() {
    if (currentSelectedHardwareId == null) return null;
    try {
      return getHardware(hardwareId: currentSelectedHardwareId!);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get current selected hardware: $e");
      currentSelectedHardwareId = null;
    }
    return null;
  }

  ListeningArea? getCurrentSelectedListeningArea() {
    if (currentSelectedListeningAreaId == null) return null;
    try {
      return getListeningArea(areaId: currentSelectedListeningAreaId!);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get current selected listening area: $e");
      currentSelectedListeningAreaId = null;
    }
    return null;
  }

  // set Listening area selection mode
  void setListeningAreaSelectionMode(bool isInSelectionMode) {
    isInListeningAreaMode = isInSelectionMode;
    isInZoneSelectionMode = false;
    currentSelectedZoneId = null;
    resetDeviceTypeIndex();
    updateProject();
  }

  // set Zone selection mode
  void setZoneSelectionMode(bool isInSelectionMode) {
    isInZoneSelectionMode = isInSelectionMode;
    isInListeningAreaMode = false;
    currentSelectedZoneId = null;
    resetDeviceTypeIndex();
    updateProject();
  }

  void setSelectedProductToAdd(ProductQueryModel? product) {
    selectedProductToAdd = product;
    updateProject();
  }

  void clearSelectedProduct() {
    selectedProductToAdd = null;
    updateProject();
  }

  void clearSelectedZone() {
    currentSelectedZoneId = null;
    updateProject();
  }

  void clearSelectedSubZone() {
    currentSelectedSubZoneId = null;
    updateProject();
  }
}
