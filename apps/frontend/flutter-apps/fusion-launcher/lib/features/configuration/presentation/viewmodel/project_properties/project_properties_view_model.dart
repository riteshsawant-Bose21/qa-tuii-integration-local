import 'package:flutter/cupertino.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension ProjectPropertiesViewModel on ProjectViewModel {
  List<Zone> get zones => projectManager.getAllZones();

  List<FloorModel> get floors => projectManager.getAllFloors();

  List<HardwareComponent> get hardwareComponents => projectManager.getAllHardwareComponents();

  List<ListeningArea> get listeningAreas => projectManager.getAllListeningAreas();

  List<SourceSet> get sourceSets => projectManager.getAllSourceSets();

  String get projectName => projectManager.getProjectName();

  String get projectId => projectManager.getProjectId();

  String? get virtualIP => projectManager.getVirtualIP();

  String get metaData => projectManager.getMetaData();

  double get minSPL => projectManager.getMinSPL();

  double get maxSPL => projectManager.getMaxSPL();

  bool get isInControlMode => projectManager.inControlMode();

  List<Color> get projectColors => projectManager.getProjectColors();

  //set project name
  void setProjectName(String name) {
    try {
      projectManager.setProjectName(name);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to set project name: $e");
      throwError("Failed to set project name: $e");
    }
  }

  //set virtual IP
  void setVirtualIP(String? ip) {
    try {
      projectManager.setVirtualIP(ip);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to set virtual IP: $e");
      throwError("Failed to set virtual IP: $e");
    }
  }

  //set meta data
  void setMetaData(String metaData) {
    try {
      projectManager.setMetaData(metaData);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to set meta data: $e");
      throwError("Failed to set meta data: $e");
    }
  }

  //set min SPL
  void setMinSPL(double minSPL) {
    try {
      projectManager.setMinSPL(minSPL);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to set min SPL: $e");
      throwError("Failed to set min SPL: $e");
    }
  }

  //set max SPL
  void setMaxSPL(double maxSPL) {
    try {
      projectManager.setMaxSPL(maxSPL);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to set max SPL: $e");
      throwError("Failed to set max SPL: $e");
    }
  }

  //set control mode
  void toggleControlMode() {
    try {
      projectManager.toggleControlMode();
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
}
