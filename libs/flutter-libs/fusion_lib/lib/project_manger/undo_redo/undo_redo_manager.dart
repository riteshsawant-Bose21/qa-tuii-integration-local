import 'package:fusion_lib/fusion_lib.dart';

extension UndoRedoManager on ProjectManager {
  //Undo / redo
  void undo() {
    Map<String, dynamic>? snapshot = projectService?.undo();
    if (snapshot != null) {
      ProjectService projectService = ProjectService.fromJson(snapshot);
      this.projectService = projectService;
    }
  }

  void redo() {
    Map<String, dynamic>? snapshot = projectService?.redo();
    if (snapshot != null) {
      ProjectService projectService = ProjectService.fromJson(snapshot);
      this.projectService = projectService;
    }
  }

  bool canUndo() {
    return projectService?.canUndo() ?? false;
  }

  bool canRedo() {
    return projectService?.canRedo() ?? false;
  }
}
