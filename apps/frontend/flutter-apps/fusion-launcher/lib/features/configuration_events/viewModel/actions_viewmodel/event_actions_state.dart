import 'package:equatable/equatable.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Base state class for the Event Actions feature
sealed class EventActionsState extends Equatable {
  const EventActionsState();

  /// Get actions list (empty for non-loaded states)
  List<SceneActionModel> get actions => <SceneActionModel>[];

  /// Get selected event ID
  String? get selectedEventId => null;

  /// Get action by ID from current actions list
  SceneActionModel? getActionById(String actionId) {
    try {
      return actions.firstWhere((SceneActionModel a) => a.id == actionId);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no event selected
class EventActionsInitial extends EventActionsState {
  const EventActionsInitial();
}

/// Loading state - fetching actions for an event
class EventActionsLoading extends EventActionsState {
  @override
  final String? selectedEventId;

  const EventActionsLoading({this.selectedEventId});

  @override
  List<Object?> get props => <Object?>[selectedEventId];
}

/// Loaded state - actions successfully loaded
class EventActionsLoaded extends EventActionsState {
  @override
  final List<SceneActionModel> actions;

  @override
  final String? selectedEventId;

  const EventActionsLoaded({
    required this.actions,
    required this.selectedEventId,
  });

  /// Create a copy with updated values
  EventActionsLoaded copyWith({
    List<SceneActionModel>? actions,
    String? selectedEventId,
  }) {
    return EventActionsLoaded(
      actions: actions ?? this.actions,
      selectedEventId: selectedEventId ?? this.selectedEventId,
    );
  }

  @override
  List<Object?> get props => <Object?>[actions, selectedEventId];
}

/// Error state - failed to load actions
class EventActionsError extends EventActionsState {
  final String message;

  @override
  final String? selectedEventId;

  const EventActionsError({
    required this.message,
    this.selectedEventId,
  });

  @override
  List<Object?> get props => <Object?>[message, selectedEventId];
}
