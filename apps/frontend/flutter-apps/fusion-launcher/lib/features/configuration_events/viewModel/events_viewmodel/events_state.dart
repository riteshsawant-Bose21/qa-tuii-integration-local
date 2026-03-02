import 'package:equatable/equatable.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Base state class for the Events feature
sealed class EventsState extends Equatable {
  const EventsState();

  /// Get events list (empty for non-loaded states)
  List<FusionEvent> get events => <FusionEvent>[];

  /// Get selected event ID
  String? get selectedEventId => null;

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no data loaded yet
class EventsInitial extends EventsState {
  const EventsInitial();
}

/// Loading state - fetching events
class EventsLoading extends EventsState {
  const EventsLoading();
}

/// Loaded state - events successfully loaded
class EventsLoaded extends EventsState {
  @override
  final List<FusionEvent> events;

  @override
  final String? selectedEventId;

  const EventsLoaded({
    required this.events,
    this.selectedEventId,
  });

  /// Create a copy with updated values
  EventsLoaded copyWith({
    List<FusionEvent>? events,
    String? selectedEventId,
    bool clearSelectedEventId = false,
  }) {
    return EventsLoaded(
      events: events ?? this.events,
      selectedEventId: clearSelectedEventId ? null : (selectedEventId ?? this.selectedEventId),
    );
  }

  @override
  List<Object?> get props => <Object?>[events, selectedEventId];
}

/// Error state - failed to load events
class EventsError extends EventsState {
  final String message;

  const EventsError({required this.message});

  @override
  List<Object?> get props => <Object?>[message];
}
