import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/scheduling/state/methods.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../state/scheduler_state.dart';

class SchedulerViewmodel extends Cubit<SchedulerState> {
  SchedulerViewmodel() : super(SchedulerState(schedules: <ScheduleConfig>[])) {
    emit(state.refreshSchedules());
  }
  void addSchedule(ScheduleConfig schedule) {
    emit(state.addSchedule(schedule));
  }

  void updateSchedule(ScheduleConfig schedule) {
    emit(state.updateSchedule(schedule));
  }

  void removeSchedule(ScheduleConfig schedule) {
    emit(state.removeSchedule(schedule));
  }
}
