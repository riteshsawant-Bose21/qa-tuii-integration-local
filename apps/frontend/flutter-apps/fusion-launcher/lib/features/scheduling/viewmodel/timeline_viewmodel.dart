import 'package:bloc/bloc.dart';
import 'package:fusion_launcher/features/scheduling/state/timeline_state.dart';
import 'package:fusion_lib/fusion_lib.dart';

class TimelineCubit extends Cubit<TimelineState> {
  TimelineCubit(List<ScheduleConfig> schedules) : super(TimelineState.initial()) {
    emit(state.refresh(schedules));
  }

  void refresh(List<ScheduleConfig> schedules) {
    emit(state.refresh(schedules));
  }

  void nextMonth() {
    goToMonth(DateTime(state.visibleMonth.year, state.visibleMonth.month + 1));
  }

  void previousMonth() {
    goToMonth(DateTime(state.visibleMonth.year, state.visibleMonth.month - 1));
  }

  void goToMonth(DateTime month) {
    if (month.isBefore(maxBackableMonth)) {
      return;
    }
    emit(state.changeMonth(month));
  }

  DateTime get maxBackableMonth {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  /// No hard upper limit – the UI year picker controls how far forward
  /// the user can navigate.
  DateTime get maxForwardableMonth => DateTime(2045, 12);
}
