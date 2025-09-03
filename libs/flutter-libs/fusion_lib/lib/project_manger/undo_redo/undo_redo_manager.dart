import 'package:fusion_lib/fusion_lib.dart';

extension UndoRedoManager on ProjectManager {
  //Undo / redo
  void undo() {
    Map<String, dynamic>? snapshot = projectService?.undo();
    if (snapshot != null) {
      ProjectService projectService = ProjectService.fromJson(snapshot);
      projectService.undoStack = this.projectService?.undoStack ?? [];
      projectService.redoStack = this.projectService?.redoStack ?? [];
      this.projectService = projectService;
    } else {
      FusionLogger.log(tag: LogTag.project, message: "Nothing to undo");
    }
  }

  void redo() {
    Map<String, dynamic>? snapshot = projectService?.redo();
    if (snapshot != null) {
      ProjectService projectService = ProjectService.fromJson(snapshot);
      projectService.undoStack = this.projectService?.undoStack ?? [];
      projectService.redoStack = this.projectService?.redoStack ?? [];
      this.projectService = projectService;
    } else {
      FusionLogger.log(tag: LogTag.project, message: "Nothing to redo");
    }
  }

  bool canUndo() {
    print("canUndo: ${projectService?.canUndo()}");
    return projectService?.canUndo() ?? false;
  }

  bool canRedo() {
    print("canRedo: ${projectService?.canRedo()}");
    return projectService?.canRedo() ?? false;
  }
}
