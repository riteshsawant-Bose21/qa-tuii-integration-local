// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:fusion_lib/fusion_lib.dart';

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

  @override
  Set<String> get selectedElementIds => <String>{};
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

  @override
  Set<String> get selectedElementIds => <String>{};
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

  @override
  Set<String> get selectedElementIds => <String>{};
}

/// State when a points drag operation has started
class PointsDragStartState extends DragToolState {
  final String layerId;
  final List<FusionCanvasElement> elements;

  PointsDragStartState({
    required this.layerId,
    required this.elements,
  });

  @override
  bool operator ==(covariant FusionToolState other) {
    if (identical(this, other)) return true;
    return other is PointsDragStartState && other.layerId == layerId && listEquals(other.elements, elements);
  }

  @override
  int get hashCode => layerId.hashCode ^ elements.hashCode;
  @override
  Set<String> get selectedLayerIds => <String>{
    layerId,
  };

  @override
  Set<String> get selectedElementIds => elements.map((FusionCanvasElement e) => e.id).toSet();
}

/// State when points are being dragged
class PointsDraggingState extends DragToolState {
  final String layerId;
  final List<FusionCanvasElement> elements;
  final Offset delta;

  PointsDraggingState({
    required this.layerId,
    required this.elements,
    required this.delta,
  });

  @override
  String toString() => 'PointsDraggingState(layerId: $layerId, elements: $elements, delta: $delta)';

  @override
  bool operator ==(covariant FusionToolState other) {
    if (identical(this, other)) return true;
    return other is PointsDraggingState && other.layerId == layerId && listEquals(other.elements, elements) && other.delta == delta;
  }

  @override
  int get hashCode => layerId.hashCode ^ elements.hashCode ^ delta.hashCode;
  @override
  Set<String> get selectedLayerIds => <String>{
    layerId,
  };

  List<String> get pointIds => elements.expand((FusionCanvasElement e) => e.pointIds).toList();

  @override
  Set<String> get selectedElementIds => elements.map((FusionCanvasElement e) => e.id).toSet();
}

/// State when a points drag operation has ended
class PointsDragEndState extends DragToolState {
  final String layerId;
  final List<FusionCanvasElement> elements;
  final Offset delta;

  PointsDragEndState({
    required this.layerId,
    required this.elements,
    required this.delta,
  });

  @override
  bool operator ==(covariant FusionToolState other) {
    if (identical(this, other)) return true;
    return other is PointsDragEndState && other.layerId == layerId && listEquals(other.elements, elements) && other.delta == delta;
  }

  @override
  int get hashCode => layerId.hashCode ^ elements.hashCode ^ delta.hashCode;
  @override
  Set<String> get selectedLayerIds => <String>{
    layerId,
  };

  @override
  Set<String> get selectedElementIds => elements.map((FusionCanvasElement e) => e.id).toSet();

  List<String> get pointIds => elements.expand((FusionCanvasElement e) => e.pointIds).toList();
}

// /// State when canvas is being panned
// class CanvasPanningState extends DragToolState {
//   final Offset delta;

//   CanvasPanningState({required this.delta});

//   @override
//   bool operator ==(covariant FusionToolState other) {
//     if (identical(this, other)) return true;
//     return other is CanvasPanningState && other.delta == delta;
//   }

//   @override
//   int get hashCode => delta.hashCode;
//   @override
//   Set<String> get selectedLayerIds => <String>{};

//   @override
//   Set<String> get selectedElementIds => <String>{};
// }
