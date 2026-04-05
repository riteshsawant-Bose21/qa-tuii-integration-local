import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

// ─── Filter mode ──────────────────────────────────────────────────────────────

enum ScheduleFilterMode {
  none,
  all,
  selected,
}

// ─── State ────────────────────────────────────────────────────────────────────

class ScheduleTabState extends Equatable {
  final List<ScheduleConfig> allSchedules;
  final bool showUpcoming;
  final ScheduleFilterMode filterMode;
  final Set<String> selectedScheduleIds;

  const ScheduleTabState({
    this.allSchedules = const <ScheduleConfig>[],
    this.showUpcoming = false,
    this.filterMode = ScheduleFilterMode.all,
    this.selectedScheduleIds = const <String>{},
  });

  // ── Derived lists ──────────────────────────────────────────────────────────

  /// Schedules shown in the Virtual Controller "Scheduled" tab.
  List<ScheduleConfig> get scheduledItems {
    switch (filterMode) {
      case ScheduleFilterMode.none:
        return <ScheduleConfig>[];
      case ScheduleFilterMode.all:
        return List<ScheduleConfig>.from(allSchedules);
      case ScheduleFilterMode.selected:
        return allSchedules.where((ScheduleConfig s) => selectedScheduleIds.contains(s.id)).toList();
    }
  }

  /// Schedules shown in the Virtual Controller "Upcoming" tab.
  /// Only items whose time is later than the current time-of-day.
  List<ScheduleConfig> get upcomingItems {
    final DateTime now = DateTime.now();
    return scheduledItems.where((ScheduleConfig s) {
      final DateTime scheduleTime = DateTime(now.year, now.month, now.day, s.time.hour, s.time.minute);
      return scheduleTime.isAfter(now);
    }).toList();
  }

  ScheduleTabState copyWith({
    List<ScheduleConfig>? allSchedules,
    bool? showUpcoming,
    ScheduleFilterMode? filterMode,
    Set<String>? selectedScheduleIds,
  }) {
    return ScheduleTabState(
      allSchedules: allSchedules ?? this.allSchedules,
      showUpcoming: showUpcoming ?? this.showUpcoming,
      filterMode: filterMode ?? this.filterMode,
      selectedScheduleIds: selectedScheduleIds ?? this.selectedScheduleIds,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    allSchedules,
    showUpcoming,
    filterMode,
    selectedScheduleIds,
  ];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class ScheduleTabCubit extends Cubit<ScheduleTabState> {
  ScheduleTabCubit() : super(const ScheduleTabState()) {
    _load();
  }

  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  void _load() {
    final List<ScheduleConfig> schedules = _projectViewModel.getAllSchedules();
    emit(state.copyWith(allSchedules: schedules));
  }

  /// Reload schedules from the project (call after external changes).
  void refresh() => _load();

  /// Toggle the "Show upcoming items" checkbox.
  void toggleShowUpcoming() {
    emit(state.copyWith(showUpcoming: !state.showUpcoming));
  }

  /// Change the active filter mode (Show none / Show all / Show selected).
  void setFilterMode(ScheduleFilterMode mode) {
    emit(state.copyWith(filterMode: mode));
  }

  /// Toggle the checkbox for a specific schedule in "Show selected" mode.
  void toggleScheduleSelection(String scheduleId) {
    final Set<String> updated = Set<String>.from(state.selectedScheduleIds);
    if (updated.contains(scheduleId)) {
      updated.remove(scheduleId);
    } else {
      updated.add(scheduleId);
    }
    emit(state.copyWith(selectedScheduleIds: updated));
  }

  /// Toggle the enabled/disabled status of a schedule and persist.
  void toggleScheduleStatus(ScheduleConfig schedule) {
    final ScheduleConfig updated = schedule.copyWith(status: !schedule.status);
    _projectViewModel.updateSchedule(schedule: updated);
    _load();
  }
}
