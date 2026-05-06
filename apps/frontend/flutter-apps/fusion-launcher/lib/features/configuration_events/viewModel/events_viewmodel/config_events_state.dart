import 'package:fusion_lib/fusion_lib.dart';

/// Base state class for the Events feature
sealed class ConfigEventsState {
  const ConfigEventsState();

  /// Get events list (empty for non-loaded states)
  List<FusionEvent> get events => <FusionEvent>[];

  /// Get selected event ID
  String? get selectedEventId => null;

  /// Get the event ID currently being recalled (null if none)
  String? get recallingEventId => null;
}

/// Initial state - no data loaded yet
class EventsInitial extends ConfigEventsState {
  const EventsInitial();
}

/// Loading state - fetching events
class EventsLoading extends ConfigEventsState {
  const EventsLoading();
}

/// Loaded state - events successfully loaded
class EventsLoaded extends ConfigEventsState {
  @override
  final List<FusionEvent> events;

  @override
  final String? selectedEventId;

  @override
  final String? recallingEventId;

  const EventsLoaded({
    required this.events,
    this.selectedEventId,
    this.recallingEventId,
  });

  /// Create a copy with updated values
  EventsLoaded copyWith({
    List<FusionEvent>? events,
    String? selectedEventId,
    bool clearSelectedEventId = false,
    String? recallingEventId,
    bool clearRecallingEventId = false,
  }) {
    return EventsLoaded(
      events: events ?? this.events,
      selectedEventId: clearSelectedEventId ? null : (selectedEventId ?? this.selectedEventId),
      recallingEventId: clearRecallingEventId ? null : (recallingEventId ?? this.recallingEventId),
    );
  }
}

/// Error state - failed to load events
class EventsError extends ConfigEventsState {
  final String message;

  const EventsError({required this.message});
}
