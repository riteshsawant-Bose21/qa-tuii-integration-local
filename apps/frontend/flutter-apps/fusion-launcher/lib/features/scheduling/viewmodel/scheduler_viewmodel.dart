import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/scheduling/model/schedule_model.dart';
import 'package:fusion_launcher/features/scheduling/state/methods.dart';

import '../state/scheduler_state.dart';

class SchedulerViewmodel extends Cubit<SchedulerState> {
  SchedulerViewmodel() : super(SchedulerState(schedules: <ScheduleModel>[]));

  void addSchedule(ScheduleModel schedule) {
    emit(state.addSchedule(schedule));
  }

  void updateSchedule(ScheduleModel schedule) {
    emit(state.updateSchedule(schedule));
  }

  void removeSchedule(ScheduleModel schedule) {
    emit(state.removeSchedule(schedule));
  }
}
