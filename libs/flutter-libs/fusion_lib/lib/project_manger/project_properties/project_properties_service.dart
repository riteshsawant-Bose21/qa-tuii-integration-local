import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension ProjectPropertiesService on ProjectService {
  int getCurrentFloorIndex() {
    return currentFloorIndex == -1 ? 0 : currentFloorIndex;
  }

  void setCurrentFloorIndex(int index) {
    currentFloorIndex = index;
  }

  void toggleControlMode() {
    isInControlMode = !isInControlMode;
  }

  bool inControlMode() {
    return isInControlMode;
  }

  double getMaxSPL() {
    return maxSPL;
  }

  double getMinSPL() {
    return minSPL;
  }

  String? getVirtualIP() {
    return virtualIP;
  }

  String getProjectName() {
    return name;
  }

  String getProjectId() {
    return id;
  }

  String getMetaData() {
    return metaData;
  }

  List<Color> getProjectColors() {
    return colors;
  }
}
