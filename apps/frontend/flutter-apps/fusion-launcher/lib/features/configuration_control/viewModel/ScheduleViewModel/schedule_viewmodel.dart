import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'schedule_state.dart';

/// ViewModel/Cubit for the Schedule tab panel.
///
/// Manages schedule display modes, selections, and status toggling.
/// Loads and persists data using [ProjectViewModel] relationships.
class ScheduleViewModel extends Cubit<ScheduleState> {
  ScheduleViewModel() : super(const ScheduleInitial());

  /// Lazy reference to ProjectViewModel.
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  /// Get current loaded state, or null if not loaded.
  ScheduleLoaded? get _loaded {
    final ScheduleState s = state;
    return s is ScheduleLoaded ? s : null;
  }

  // ─── Data Loading ──────────────────────────────────────────────────────────

  /// Loads schedule data for the specified controller.
  void loadData(String controllerId) {
    emit(const ScheduleLoading());

    try {
      final List<ScheduleConfig> allSchedules = _projectViewModel.getAllSchedules();
      final ControllerSchedulePageConfig config = _projectViewModel.getControllerScheduleConfig(controllerId);
      final Set<String> selectedScheduleIds = _projectViewModel.getSelectedScheduleIds(controllerId);

      emit(
        ScheduleLoaded(
          allSchedules: allSchedules,
          showUpcoming: config.showUpcoming,
          filterMode: ScheduleFilterModeX.fromKey(config.displayMode),
          selectedScheduleIds: selectedScheduleIds,
          controllerId: controllerId,
        ),
      );
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'ScheduleViewModel: failed to load data: $e');
      emit(ScheduleError(message: 'Failed to load schedule data: $e'));
    }
  }

  /// Reloads data from persistence.
  void refresh() {
    final ScheduleLoaded? loaded = _loaded;
    if (loaded?.controllerId != null) {
      loadData(loaded!.controllerId!);
    }
  }

  // ─── Schedule Actions ──────────────────────────────────────────────────────

  /// Toggle the "Show upcoming items" checkbox and persist.
  void toggleShowUpcoming() {
    final ScheduleLoaded? loaded = _loaded;
    if (loaded == null) return;

    final bool next = !loaded.showUpcoming;
    _persistConfig(loaded.copyWith(showUpcoming: next));
    emit(loaded.copyWith(showUpcoming: next));
  }

  /// Set filter mode (Show none / Show all / Show selected) and persist.
  void setFilterMode(ScheduleFilterMode mode) {
    final ScheduleLoaded? loaded = _loaded;
    if (loaded == null) return;

    _persistConfig(loaded.copyWith(filterMode: mode));
    emit(loaded.copyWith(filterMode: mode));
  }

  /// Toggle a schedule checkbox in "Show selected" mode and persist.
  void toggleScheduleSelection(String scheduleId) {
    final ScheduleLoaded? loaded = _loaded;
    if (loaded == null) return;

    final Set<String> updated = Set<String>.from(loaded.selectedScheduleIds);
    if (updated.contains(scheduleId)) {
      updated.remove(scheduleId);
    } else {
      updated.add(scheduleId);
    }

    final ScheduleLoaded next = loaded.copyWith(selectedScheduleIds: updated);
    _persistConfig(next);
    emit(next);
  }

  /// Toggle the enabled/disabled status of a schedule.
  void toggleScheduleStatus(ScheduleConfig schedule) {
    _projectViewModel.updateSchedule(
      schedule: schedule.copyWith(status: !schedule.status),
    );
    refresh();
  }

  // ─── Persistence ───────────────────────────────────────────────────────────

  /// Persists schedule configuration for the controller.
  void _persistConfig(ScheduleLoaded state) {
    if (state.controllerId == null) return;

    _projectViewModel.setControllerScheduleConfig(
      controllerId: state.controllerId!,
      config: ControllerSchedulePageConfig(
        displayMode: state.filterMode.key,
        showUpcoming: state.showUpcoming,
      ),
    );

    // Persist selected schedule IDs
    _projectViewModel.setSelectedScheduleIds(
      controllerId: state.controllerId!,
      scheduleIds: state.selectedScheduleIds,
    );
  }
}
