// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../fusion_tool_state.dart';
import 'select_tool_state.dart';

/// Base state for drag operations
abstract class DragToolState extends SelectToolState {}

/// State when a layer drag operation has started
class LayerDragStartState extends DragToolState {
  final String layerId;

  LayerDragStartState({required this.layerId});

  @override
  Set<String> get selectedLayerIds => <String>{
    layerId,
  };
}

/// State when a layer is being dragged
class LayerDraggingState extends DragToolState {
  final String layerId;
  final Offset delta;

  LayerDraggingState({
    required this.layerId,
    required this.delta,
  });

  @override
  String toString() => 'LayerDraggingState(layerId: $layerId, delta: $delta)';

  @override
  bool operator ==(covariant FusionToolState other) {
    if (identical(this, other)) return true;
    return other is LayerDraggingState && other.layerId == layerId && other.delta == delta;
  }

  @override
  int get hashCode => layerId.hashCode ^ delta.hashCode;
  @override
  Set<String> get selectedLayerIds => <String>{
    layerId,
  };
}

/// State when a layer drag operation has ended
class LayerDragEndState extends DragToolState {
  final String layerId;
  final Offset delta;

  LayerDragEndState({
    required this.layerId,
    required this.delta,
  });

  @override
  bool operator ==(covariant FusionToolState other) {
    if (identical(this, other)) return true;
    return other is LayerDragEndState && other.layerId == layerId && other.delta == delta;
  }

  @override
  int get hashCode => layerId.hashCode ^ delta.hashCode;
  @override
  Set<String> get selectedLayerIds => <String>{
    layerId,
  };
}

/// State when a points drag operation has started
class PointsDragStartState extends DragToolState {
  final String layerId;
  final List<String> pointIds;

  PointsDragStartState({
    required this.layerId,
    required this.pointIds,
  });

  @override
  bool operator ==(covariant FusionToolState other) {
    if (identical(this, other)) return true;
    return other is PointsDragStartState && other.layerId == layerId && listEquals(other.pointIds, pointIds);
  }

  @override
  int get hashCode => layerId.hashCode ^ pointIds.hashCode;
  @override
  Set<String> get selectedLayerIds => <String>{
    layerId,
  };
}

/// State when points are being dragged
class PointsDraggingState extends DragToolState {
  final String layerId;
  final List<String> pointIds;
  final Offset delta;

  PointsDraggingState({
    required this.layerId,
    required this.pointIds,
    required this.delta,
  });

  @override
  String toString() => 'PointsDraggingState(layerId: $layerId, pointIds: $pointIds, delta: $delta)';

  @override
  bool operator ==(covariant FusionToolState other) {
    if (identical(this, other)) return true;
    return other is PointsDraggingState && other.layerId == layerId && listEquals(other.pointIds, pointIds) && other.delta == delta;
  }

  @override
  int get hashCode => layerId.hashCode ^ pointIds.hashCode ^ delta.hashCode;
  @override
  Set<String> get selectedLayerIds => <String>{
    layerId,
  };
}

/// State when a points drag operation has ended
class PointsDragEndState extends DragToolState {
  final String layerId;
  final List<String> pointIds;
  final Offset delta;

  PointsDragEndState({
    required this.layerId,
    required this.pointIds,
    required this.delta,
  });

  @override
  bool operator ==(covariant FusionToolState other) {
    if (identical(this, other)) return true;
    return other is PointsDragEndState && other.layerId == layerId && listEquals(other.pointIds, pointIds) && other.delta == delta;
  }

  @override
  int get hashCode => layerId.hashCode ^ pointIds.hashCode ^ delta.hashCode;
  @override
  Set<String> get selectedLayerIds => <String>{
    layerId,
  };
}

/// State when canvas is being panned
class CanvasPanningState extends DragToolState {
  final Offset delta;

  CanvasPanningState({required this.delta});

  @override
  bool operator ==(covariant FusionToolState other) {
    if (identical(this, other)) return true;
    return other is CanvasPanningState && other.delta == delta;
  }

  @override
  int get hashCode => delta.hashCode;
  @override
  Set<String> get selectedLayerIds => <String>{};
}
