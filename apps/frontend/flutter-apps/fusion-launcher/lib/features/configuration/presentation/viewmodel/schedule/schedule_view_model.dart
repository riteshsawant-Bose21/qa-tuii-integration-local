import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension ScheduleViewModel on ProjectViewModel {
  void addNewSchedule({required ScheduleConfig schedule, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addNewSchedule(schedule);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Add New Schedule Error  ${e.toString()}");
    }
  }

  void updateSchedule({required ScheduleConfig schedule, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateSchedule(schedule);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Update Schedule Error  ${e.toString()}");
    }
  }

  void removeSchedule({required String scheduleId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeSchedule(scheduleId);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Delete Schedule Error  ${e.toString()}");
    }
  }

  List<ScheduleConfig> getAllSchedules() {
    try {
      return projectManager.getAllSchedules();
    } catch (e) {
      throwError("Get All Schedules Error  ${e.toString()}");
      return <ScheduleConfig>[];
    }
  }

  void reOrderSchedules({required String scheduleIdToMove, required String scheduleAtNewIndexId}) {
    try {
      recordSnapshot();
      projectManager.reOrderSchedule(
        scheduleIdToMove: scheduleIdToMove,
        scheduleAtNewIndexId: scheduleAtNewIndexId,
      );
      saveProject();
    } catch (e) {
      throwError("Reorder Schedules Error  ${e.toString()}");
    }
  }
}
