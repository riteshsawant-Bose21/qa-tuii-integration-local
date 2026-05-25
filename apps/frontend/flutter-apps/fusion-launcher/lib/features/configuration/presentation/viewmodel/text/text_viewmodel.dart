import 'package:fusion_lib/fusion_logger/logger.dart';
import 'package:fusion_lib/models/project_entities/floor_text_model.dart';
import 'package:fusion_lib/project_manger/text/text_manager.dart';

import '../project_view_model.dart';

extension TextViewModel on ProjectViewModel {
  void addText({required FloorText floorText, required String floorId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addText(floorText, floorId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'Failed to add text: $e');
    }
  }

  void updateText({required FloorText floorText, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateText(floorText);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'Failed to update text: $e');
      throwError('Failed to update text: $e');
    }
  }

  void removeText({required String textId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeText(textId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'Failed to remove text: $e');
    }
  }

  FloorText getText({required String textId}) {
    try {
      return projectManager.getTextById(textId);
    } catch (e) {
      throw Exception('text not found: $e');
    }
  }

  List<FloorText> getAllTexts() {
    try {
      return projectManager.getAllTexts();
    } catch (e) {
      throw Exception('failed to get texts: $e');
    }
  }

  List<FloorText> getTextsForFloor({required String floorId}) {
    try {
      return projectManager.getTextsForFloor(floorId);
    } catch (e) {
      throw Exception('failed to get texts for floor: $e');
    }
  }
}
