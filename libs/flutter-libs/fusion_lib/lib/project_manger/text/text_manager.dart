import '../../fusion_lib.dart';

extension TextManager on ProjectManager {
  void addText(FloorText floorText, String floorId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addText(floorText, floorId);
  }

  void updateText(FloorText floorText) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateText(floorText);
  }

  void removeText(String textId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeText(textId);
  }

  FloorText getTextById(String textId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getTextById(textId);
  }

  List<FloorText> getTextsForFloor(String floorId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getTextsForFloor(floorId);
  }

  List<FloorText> getAllTexts() {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getAllTexts();
  }
}
