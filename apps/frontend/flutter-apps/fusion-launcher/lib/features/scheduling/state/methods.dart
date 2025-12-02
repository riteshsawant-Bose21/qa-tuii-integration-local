import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/models/project_entities/non_processing/scheduler_config.dart';

import 'scheduler_state.dart';

extension SchedulerStateMethods on SchedulerState {
  SchedulerState copyWith({
    List<ScheduleConfig>? schedules,
  }) {
    return SchedulerState(
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
}
