part of 'scheduler_state.dart';

extension SchedulerStateMethods on SchedulerState {
  SchedulerState copyWith({
    List<ScheduleConfig>? schedules,
  }) {
    return IdleSchedulerState(
      schedules: schedules ?? this.schedules,
    );
  }

  SchedulerState addSchedule(ScheduleConfig schedule) {
    serviceLocator<ProjectViewModel>().addNewSchedule(schedule: schedule);
    return refreshSchedules();
  }

  SchedulerState refreshSchedules() {
    final List<ScheduleConfig> val = serviceLocator<ProjectViewModel>().getAllSchedules();
    return copyWith(schedules: val);
  }

  SchedulerState updateSchedule(ScheduleConfig schedule) {
    serviceLocator<ProjectViewModel>().updateSchedule(schedule: schedule);
    return refreshSchedules();
  }

  SchedulerState removeSchedule(ScheduleConfig schedule) {
    serviceLocator<ProjectViewModel>().removeSchedule(scheduleId: schedule.id);
    return refreshSchedules();
  }

  SchedulerState searchSchedules(String query) {
    final List<ScheduleConfig> allSchedules = switch (this) {
      final SearchingSchedulerState searchingState => searchingState.allSchedules,
      final IdleSchedulerState idleState => idleState.schedules,
      _ => <ScheduleConfig>[],
    };
    final List<ScheduleConfig> filteredSchedules =
        allSchedules.where((ScheduleConfig schedule) => schedule.name.toLowerCase().contains(query.toLowerCase())).toList();

    return SearchingSchedulerState(
      filteredSchedule: filteredSchedules,
      allSchedules: allSchedules,
      searchQuery: query,
    );
  }
}
