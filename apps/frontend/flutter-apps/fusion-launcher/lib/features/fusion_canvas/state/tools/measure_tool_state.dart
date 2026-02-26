import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';

class MeasureToolState extends FusionToolState {
  final Offset? start;
  final Offset? end;
  MeasureToolState({
    this.start,
    this.end,
  });

  @override
  bool operator ==(covariant FusionToolState other) {
    if (identical(this, other)) return true;

    return other is MeasureToolState && other.start == start && other.end == end;
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;

  MeasureToolState copyWith({
    Offset? start,
    Offset? end,
  }) {
    return MeasureToolState(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}
