import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/non_processing/scheduler_config.dart';

part 'scheduler_state_modifer.dart';

abstract class SchedulerState {
  final List<ScheduleConfig> schedules;

  SchedulerState({required this.schedules});
}

class IdleSchedulerState extends SchedulerState {
  IdleSchedulerState({required super.schedules});
}

class SearchingSchedulerState extends SchedulerState {
  final List<ScheduleConfig> allSchedules;
  final String searchQuery;

  SearchingSchedulerState({
    required List<ScheduleConfig> filteredSchedule,
    required this.allSchedules,
    required this.searchQuery,
  }) : super(schedules: filteredSchedule);
}
