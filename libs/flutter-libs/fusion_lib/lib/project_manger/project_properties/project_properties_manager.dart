import 'package:flutter/cupertino.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension ProjectPropertiesManager on ProjectManager {
  //get Project id
  String getProjectId() {
    return projectService!.getProjectId();
  }

  //get Project name
  String getProjectName() {
    return projectService!.getProjectName();
  }

  //set Project name
  void setProjectName(String name) {
    projectService = projectService!.copyWith(name: name, projectName: name);
  }

  //get Project colors
  List<Color> getProjectColors() {
    return projectService!.getProjectColors();
  }

  //set Project colors
  void setProjectColors(List<Color> colors) {
    projectService = projectService!.copyWith(colors: colors);
  }

  //get Project virtual IP
  String? getVirtualIP() {
    return projectService!.getVirtualIP();
  }

  //set Project virtual IP
  void setVirtualIP(String? virtualIP) {
    projectService = projectService!.updateVip(virtualIP);
  }

  //get Project min SPL
  double getMinSPL() {
    return projectService!.getMinSPL();
  }

  //set Project min SPL
  void setMinSPL(double minSPL) {
    projectService = projectService!.copyWith(minSPL: minSPL);
  }

  //get Project max SPL
  double getMaxSPL() {
    return projectService!.getMaxSPL();
  }

  //set Project max SPL
  void setMaxSPL(double maxSPL) {
    projectService = projectService!.copyWith(maxSPL: maxSPL);
  }

  //get current floor index
  int getCurrentFloorIndex() {
    return projectService!.getCurrentFloorIndex();
  }

  //set current floor index
  void setCurrentFloorIndex(int index) {
    projectService!.setCurrentFloorIndex(index);
  }

  //toggle control mode
  void toggleControlMode() {
    projectService!.toggleControlMode();
  }

  //check if in control mode
  bool inControlMode() {
    return projectService!.inControlMode();
  }

  //get all fusion devices
  List<FusionDsp> getAllFusionDevices() {
    return projectService!.getAllFusionDevices();
  }

  void updateProjectMetaData({required ProjectMetaData metaData}) {
    try {
      if (projectService == null) {
        FusionLogger.log(tag: LogTag.exceptions, message: "No project is currently loaded. Cannot update metadata.");
        return;
      }
      projectService = projectService!.copyWith(
        metadata: metaData,
      );
      saveCurrentProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.exceptions, message: "Error updating project metadata: $e");
    }
  }

  ProjectMetaData? getProjectMetadata() {
    try {
      if (projectService == null) {
        FusionLogger.log(tag: LogTag.exceptions, message: "No project is currently loaded. Cannot get metadata.");
        return null;
      }
      return projectService!.metadata;
    } catch (e) {
      FusionLogger.log(tag: LogTag.exceptions, message: "Error getting project metadata: $e");
    }
    return null;
  }
}
