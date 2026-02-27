import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';

abstract class MeasureToolState extends FusionToolState {}

class IdleMeasureToolState extends MeasureToolState {}

class DrawingMeasureToolState extends MeasureToolState {
  final Offset start;
  final Offset? end;

  DrawingMeasureToolState({
    required this.start,
    this.end,
  });

  @override
  bool operator ==(covariant FusionToolState other) {
    if (identical(this, other)) return true;

    return other is DrawingMeasureToolState && other.start == start && other.end == end;
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;

  DrawingMeasureToolState copyWith({
    Offset? start,
    Offset? end,
  }) {
    return DrawingMeasureToolState(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  /// Whether this measurement is complete
  bool get isComplete => end != null;
}
