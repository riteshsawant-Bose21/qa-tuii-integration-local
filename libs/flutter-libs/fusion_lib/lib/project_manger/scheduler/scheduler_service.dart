import 'package:fusion_lib/fusion_lib.dart';

extension SchedulerService on ProjectService {
  void addNewSchedule(ScheduleConfig schedule) {
    schedulerConfig.add(schedule.id, schedule);
  }

  void updateSchedule(ScheduleConfig schedule) {
    if (!schedulerConfig.exists(schedule.id)) {
      throw Exception("Schedule with ID ${schedule.id} does not exist.");
    }
    schedulerConfig.add(schedule.id, schedule);
  }

  void removeSchedule(String scheduleId) {
    if (!schedulerConfig.exists(scheduleId)) {
      throw Exception("Schedule with ID $scheduleId does not exist.");
    }
    schedulerConfig.remove(scheduleId);
  }

  List<ScheduleConfig> getAllSchedules() {
    return schedulerConfig.getAll();
  }

  Map<String, ScheduleConfig> reOrderSchedule({required String scheduleIdToMove, required String scheduleAtNewIndexId}) {
    List<ScheduleConfig> items = getAllSchedules();

    // Find indices
    int fromIndex = items.indexWhere((s) => s.id == scheduleIdToMove);
    int toIndex = items.indexWhere((s) => s.id == scheduleAtNewIndexId);

    // Validate
    if (fromIndex == -1 || toIndex == -1) {
      throw ArgumentError('Invalid Schedule IDs');
    }

    // Reorder using List operations
    ScheduleConfig item = items.removeAt(fromIndex);
    items.insert(toIndex, item);

    // Convert back to Map
    return {for (var s in items) s.id: s};
  }
}
