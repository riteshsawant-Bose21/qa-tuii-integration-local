import '../model/schedule_model.dart';
import 'scheduler_state.dart';

extension SchedulerStateMethods on SchedulerState {
  SchedulerState copyWith({
    List<ScheduleModel>? schedules,
  }) {
    return SchedulerState(
      schedules: schedules ?? this.schedules,
    );
  }

  SchedulerState addSchedule(ScheduleModel schedule) {
    final List<ScheduleModel> val = List<ScheduleModel>.from(schedules);
    val.add(schedule);
    return copyWith(schedules: val);
  }

  SchedulerState updateSchedule(ScheduleModel schedule) {
    final List<ScheduleModel> val =
        schedules.map((ScheduleModel e) {
          if (e.id == schedule.id) {
            return schedule;
          }
          return e;
        }).toList();
    return copyWith(schedules: val);
  }

  SchedulerState removeSchedule(ScheduleModel schedule) {
    final List<ScheduleModel> val = List<ScheduleModel>.from(schedules);
    val.removeWhere((ScheduleModel element) => element.id == schedule.id);
    return copyWith(schedules: val);
  }
}
