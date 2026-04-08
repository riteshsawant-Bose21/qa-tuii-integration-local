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
  final Set<String> layerIds;

  LayerDragStartState({required this.layerIds});

  @override
  bool operator ==(covariant FusionToolState other) {
    if (identical(this, other)) return true;
    return other is LayerDragStartState && setEquals(other.layerIds, layerIds);
  }

  @override
  int get hashCode => layerIds.hashCode;

  @override
  Set<String> get selectedLayerIds => layerIds;

  @override
  Set<String> get selectedElementIds => <String>{};

  @override
  String toString() => 'LayerDragStartState(layerIds: $layerIds)';
}

/// State when a layer is being dragged
class LayerDraggingState extends DragToolState {
  final Set<String> layerIds;
  final Offset delta;

  LayerDraggingState({
    required this.layerIds,
    required this.delta,
  });

  @override
  String toString() => 'LayerDraggingState(layerIds: $layerIds, delta: $delta)';

  @override
  bool operator ==(covariant FusionToolState other) {
    if (identical(this, other)) return true;
    return other is LayerDraggingState && setEquals(other.layerIds, layerIds) && other.delta == delta;
  }

  @override
  int get hashCode => layerIds.hashCode ^ delta.hashCode;
  @override
  Set<String> get selectedLayerIds => layerIds;

  @override
  Set<String> get selectedElementIds => <String>{};
}

/// State when a layer drag operation has ended
class LayerDragEndState extends DragToolState {
  final Set<String> layerIds;
  final Offset delta;

  LayerDragEndState({
    required this.layerIds,
    required this.delta,
  });

  @override
  bool operator ==(covariant FusionToolState other) {
    if (identical(this, other)) return true;
    return other is LayerDragEndState && setEquals(other.layerIds, layerIds) && other.delta == delta;
  }

  @override
  int get hashCode => layerIds.hashCode ^ delta.hashCode;
  @override
  Set<String> get selectedLayerIds => layerIds;

  @override
  Set<String> get selectedElementIds => <String>{};
}

/// State when a points drag operation has started
class PointsDragStartState extends DragToolState {
  final Set<String> layerIds;
  final List<FusionCanvasElement> elements;

  PointsDragStartState({
    required this.layerIds,
    required this.elements,
  });

  @override
  bool operator ==(covariant FusionToolState other) {
    if (identical(this, other)) return true;
    return other is PointsDragStartState && setEquals(other.layerIds, layerIds) && listEquals(other.elements, elements);
  }

  @override
  int get hashCode => layerIds.hashCode ^ elements.hashCode;
  @override
  Set<String> get selectedLayerIds => layerIds;

  @override
  Set<String> get selectedElementIds => elements.map((FusionCanvasElement e) => e.id).toSet();

  @override
  String toString() => 'PointsDragStartState(layerIds: $layerIds, elements: $elements)';
}

/// State when points are being dragged
class PointsDraggingState extends DragToolState {
  final Set<String> layerIds;
  final List<FusionCanvasElement> elements;
  final Offset delta;

  PointsDraggingState({
    required this.layerIds,
    required this.elements,
    required this.delta,
  });

  @override
  String toString() => 'PointsDraggingState(layerIds: $layerIds, elements: $elements, delta: $delta)';

  @override
  bool operator ==(covariant FusionToolState other) {
    if (identical(this, other)) return true;
    return other is PointsDraggingState && setEquals(other.layerIds, layerIds) && listEquals(other.elements, elements) && other.delta == delta;
  }

  @override
  int get hashCode => layerIds.hashCode ^ elements.hashCode ^ delta.hashCode;
  @override
  Set<String> get selectedLayerIds => layerIds;

  List<String> get pointIds => elements.expand((FusionCanvasElement e) => e.pointIds).toList();

  @override
  Set<String> get selectedElementIds => elements.map((FusionCanvasElement e) => e.id).toSet();
}

/// State when a points drag operation has ended
class PointsDragEndState extends DragToolState {
  final Set<String> layerIds;
  final List<FusionCanvasElement> elements;
  final Offset delta;

  PointsDragEndState({
    required this.layerIds,
    required this.elements,
    required this.delta,
  });

  @override
  bool operator ==(covariant FusionToolState other) {
    if (identical(this, other)) return true;
    return other is PointsDragEndState && setEquals(other.layerIds, layerIds) && listEquals(other.elements, elements) && other.delta == delta;
  }

  @override
  int get hashCode => layerIds.hashCode ^ elements.hashCode ^ delta.hashCode;
  @override
  Set<String> get selectedLayerIds => layerIds;

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
