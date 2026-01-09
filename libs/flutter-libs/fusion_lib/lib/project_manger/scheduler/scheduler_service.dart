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

    final parentEvents = relationships.getParents(RelationshipType.eventsItemMapping, scheduleId);
    final copyOfParentEvents = List<String>.from(parentEvents);
    for (final eventId in copyOfParentEvents) {
      removeEvent(eventId);
    }

    schedulerConfig.remove(scheduleId);
  }

  List<ScheduleConfig> getAllSchedules() {
    return schedulerConfig.getAll();
  }
}
