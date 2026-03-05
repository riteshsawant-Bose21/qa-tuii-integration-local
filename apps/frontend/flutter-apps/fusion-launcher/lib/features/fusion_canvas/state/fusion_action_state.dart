// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:flutter/foundation.dart';

abstract class FusionActionState {}

class FusionToolActiveState extends FusionActionState {}

class FusionLayerDragStartState extends FusionActionState {
  final String layerId;

  FusionLayerDragStartState({
    required this.layerId,
  });
}

class FusionLayerDraggingState extends FusionActionState {
  final String layerId;
  final Offset delta;

  FusionLayerDraggingState({
    required this.layerId,
    required this.delta,
  });

  @override
  String toString() => 'FusionLayerDraggingState(layerId: $layerId, delta: $delta)';

  @override
  bool operator ==(covariant FusionActionState other) {
    if (identical(this, other)) return true;

    return other is FusionLayerDraggingState && other.layerId == layerId && other.delta == delta;
  }

  @override
  int get hashCode => layerId.hashCode ^ delta.hashCode;
}

class FusionLayerDragEndState extends FusionActionState {
  final String layerId;
  final Offset delta;

  FusionLayerDragEndState({
    required this.layerId,
    required this.delta,
  });

  @override
  bool operator ==(covariant FusionActionState other) {
    if (identical(this, other)) return true;

    return other is FusionLayerDragEndState && other.layerId == layerId && other.delta == delta;
  }

  @override
  int get hashCode => layerId.hashCode ^ delta.hashCode;
}

class FusionPointsDragStartState extends FusionActionState {
  final String layerId;
  final List<String> pointId;

  FusionPointsDragStartState({
    required this.layerId,
    required this.pointId,
  });

  @override
  bool operator ==(covariant FusionActionState other) {
    if (identical(this, other)) return true;

    return other is FusionPointsDragStartState && other.layerId == layerId && listEquals(other.pointId, pointId);
  }

  @override
  int get hashCode => layerId.hashCode ^ pointId.hashCode;
}

class FusionPointsDraggingState extends FusionActionState {
  final String layerId;
  final List<String> pointId;
  final Offset delta;

  FusionPointsDraggingState({
    required this.layerId,
    required this.pointId,
    required this.delta,
  });

  @override
  String toString() => 'FusionPointsDraggingState(layerId: $layerId, pointId: $pointId, delta: $delta)';
}

class FusionPointsDragEndState extends FusionActionState {
  final String layerId;
  final List<String> pointId;
  final Offset delta;
  FusionPointsDragEndState({
    required this.layerId,
    required this.pointId,
    required this.delta,
  });

  @override
  bool operator ==(covariant FusionActionState other) {
    if (identical(this, other)) return true;

    return other is FusionPointsDragEndState && other.layerId == layerId && listEquals(other.pointId, pointId) && other.delta == delta;
  }

  @override
  int get hashCode => layerId.hashCode ^ pointId.hashCode ^ delta.hashCode;
}

class FusionCanvasPanningState extends FusionActionState {
  final Offset delta;

  FusionCanvasPanningState({
    required this.delta,
  });
}
