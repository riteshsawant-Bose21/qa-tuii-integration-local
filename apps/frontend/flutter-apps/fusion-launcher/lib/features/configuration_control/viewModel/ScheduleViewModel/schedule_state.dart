import 'package:equatable/equatable.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Schedule filter mode for the Schedule tab.
enum ScheduleFilterMode {
  none,
  all,
  selected,
}

extension ScheduleFilterModeX on ScheduleFilterMode {
  String get key => name;

  static ScheduleFilterMode fromKey(String key) {
    return ScheduleFilterMode.values.firstWhere(
      (ScheduleFilterMode m) => m.name == key,
      orElse: () => ScheduleFilterMode.all,
    );
  }
}

/// State for the Schedule tab panel.
sealed class ScheduleState extends Equatable {
  const ScheduleState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no data loaded yet.
class ScheduleInitial extends ScheduleState {
  const ScheduleInitial();
}

/// Loading state - fetching data.
class ScheduleLoading extends ScheduleState {
  const ScheduleLoading();
}

/// Loaded state - schedules successfully loaded.
class ScheduleLoaded extends ScheduleState {
  /// All schedules loaded from the project.
  final List<ScheduleConfig> allSchedules;

  /// Whether "Show upcoming items" is checked (initially true).
  final bool showUpcoming;

  /// Active filter mode in the Schedule tab.
  final ScheduleFilterMode filterMode;

  /// Schedule IDs checked in "Show selected" mode.
  final Set<String> selectedScheduleIds;

  /// The controller ID this state belongs to.
  final String? controllerId;

  const ScheduleLoaded({
    required this.allSchedules,
    this.showUpcoming = true,
    this.filterMode = ScheduleFilterMode.all,
    this.selectedScheduleIds = const <String>{},
    this.controllerId,
  });

  /// Get filtered schedules based on the current filter mode.
  List<ScheduleConfig> get filteredSchedules {
    switch (filterMode) {
      case ScheduleFilterMode.none:
        return <ScheduleConfig>[];
      case ScheduleFilterMode.all:
        return allSchedules;
      case ScheduleFilterMode.selected:
        return allSchedules.where((ScheduleConfig s) => selectedScheduleIds.contains(s.id)).toList();
    }
  }

  /// Get upcoming schedules (enabled only).
  List<ScheduleConfig> get upcomingSchedules {
    if (!showUpcoming) return <ScheduleConfig>[];
    return filteredSchedules.where((ScheduleConfig s) => s.status).toList();
  }

  ScheduleLoaded copyWith({
    List<ScheduleConfig>? allSchedules,
    bool? showUpcoming,
    ScheduleFilterMode? filterMode,
    Set<String>? selectedScheduleIds,
    Object? controllerId = _sentinel,
  }) {
    return ScheduleLoaded(
      allSchedules: allSchedules ?? this.allSchedules,
      showUpcoming: showUpcoming ?? this.showUpcoming,
      filterMode: filterMode ?? this.filterMode,
      selectedScheduleIds: selectedScheduleIds ?? this.selectedScheduleIds,
      controllerId: identical(controllerId, _sentinel) ? this.controllerId : controllerId as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    allSchedules,
    showUpcoming,
    filterMode,
    selectedScheduleIds,
    controllerId,
  ];
}

/// Error state - failed to load data.
class ScheduleError extends ScheduleState {
  final String message;

  const ScheduleError({required this.message});

  @override
  List<Object?> get props => <Object?>[message];
}

/// Sentinel for nullable copyWith parameters.
const Object _sentinel = Object();
