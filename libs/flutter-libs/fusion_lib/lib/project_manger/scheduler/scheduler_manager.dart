import 'package:fusion_lib/fusion_lib.dart';

extension SchedulerManager on ProjectManager {
  void addNewSchedule(ScheduleConfig schedule) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.addNewSchedule(schedule);
  }

  void updateSchedule(ScheduleConfig schedule) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.updateSchedule(schedule);
  }

  void removeSchedule(String scheduleId) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.removeSchedule(scheduleId);
  }

  List<ScheduleConfig> getAllSchedules() {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    return projectService!.getAllSchedules();
  }

  void reOrderSchedule({required String scheduleIdToMove, required String scheduleAtNewIndexId}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    Map<String, ScheduleConfig> reorderedList = projectService!.reOrderSchedule(
      scheduleIdToMove: scheduleIdToMove,
      scheduleAtNewIndexId: scheduleAtNewIndexId,
    );
    projectService = projectService!.copyWith(
      schedulerConfig: projectService!.schedulerConfig.copyWith(reorderedList),
    );
  }
}
