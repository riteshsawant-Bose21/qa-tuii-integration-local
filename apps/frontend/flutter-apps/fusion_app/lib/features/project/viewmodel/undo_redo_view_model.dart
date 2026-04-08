import 'package:fusion_app/features/landing/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension UndoRedoViewModel on ProjectViewModel {
  bool get canUndo => projectManager.canUndo();

  bool get canRedo => projectManager.canRedo();

  void recordSnapshot() {
    try {
      projectManager.recordSnapshot();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to record snapshot: $e");
      throwError("Failed to record snapshot: $e");
    }
  }

  void undo() {
    try {
      projectManager.undo();
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to undo: $e");
      throwError("Failed to undo: $e");
    }
  }

  void redo() {
    try {
      projectManager.redo();
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to redo: $e");
      throwError("Failed to redo: $e");
    }
  }
}
