// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../fusion_tool_state.dart';

/// Base state for selection tool
abstract class SelectToolState extends FusionToolState {
  /// Set of selected layer IDs
  Set<String> get selectedLayerIds;
  Set<String> get selectedElementIds;

  /// Check if a layer is selected
  bool isLayerSelected(String? layerId) => layerId != null && selectedLayerIds.contains(layerId);

  /// Check if an element is selected
  bool isElementSelected(String? elementId) => elementId != null && selectedElementIds.contains(elementId);
}

/// Idle state - no active selection operation
class IdleSelectToolState extends SelectToolState {
  final Set<String> _selectedLayerIds;
  final Set<String> _selectedElementIds;

  IdleSelectToolState({Set<String>? selectedLayerIds, Set<String>? selectedElementIds})
    : _selectedLayerIds = selectedLayerIds ?? <String>{},
      _selectedElementIds = selectedElementIds ?? <String>{};

  @override
  Set<String> get selectedLayerIds => _selectedLayerIds;

  @override
  Set<String> get selectedElementIds => _selectedElementIds;

  IdleSelectToolState copyWith({Set<String>? selectedLayerIds, Set<String>? selectedElementIds}) {
    return IdleSelectToolState(
      selectedLayerIds: selectedLayerIds ?? _selectedLayerIds,
      selectedElementIds: selectedElementIds ?? _selectedElementIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IdleSelectToolState && setEquals(other._selectedLayerIds, _selectedLayerIds) && setEquals(other._selectedElementIds, _selectedElementIds);
  }

  @override
  int get hashCode => _selectedLayerIds.hashCode ^ _selectedElementIds.hashCode;

  @override
  String toString() => 'IdleSelectToolState(_selectedLayerIds: $_selectedLayerIds, _selectedElementIds: $_selectedElementIds)';
}

/// Active marquee selection state while dragging on empty canvas.
class MarqueeSelectToolState extends SelectToolState {
  final Offset startPosition;
  final Offset currentPosition;
  final Set<String> _selectedLayerIds;
  final Set<String> _selectedElementIds;

  MarqueeSelectToolState({
    required this.startPosition,
    required this.currentPosition,
    Set<String>? selectedLayerIds,
    Set<String>? selectedElementIds,
  }) : _selectedLayerIds = selectedLayerIds ?? <String>{},
       _selectedElementIds = selectedElementIds ?? <String>{};

  Rect get selectionRect => Rect.fromPoints(startPosition, currentPosition);

  @override
  Set<String> get selectedLayerIds => _selectedLayerIds;

  @override
  Set<String> get selectedElementIds => _selectedElementIds;

  MarqueeSelectToolState copyWith({
    Offset? startPosition,
    Offset? currentPosition,
    Set<String>? selectedLayerIds,
    Set<String>? selectedElementIds,
  }) {
    return MarqueeSelectToolState(
      startPosition: startPosition ?? this.startPosition,
      currentPosition: currentPosition ?? this.currentPosition,
      selectedLayerIds: selectedLayerIds ?? _selectedLayerIds,
      selectedElementIds: selectedElementIds ?? _selectedElementIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarqueeSelectToolState &&
        other.startPosition == startPosition &&
        other.currentPosition == currentPosition &&
        setEquals(other._selectedLayerIds, _selectedLayerIds) &&
        setEquals(other._selectedElementIds, _selectedElementIds);
  }

  @override
  int get hashCode {
    return startPosition.hashCode ^ currentPosition.hashCode ^ _selectedLayerIds.hashCode ^ _selectedElementIds.hashCode;
  }

  @override
  String toString() {
    return 'MarqueeSelectToolState(startPosition: $startPosition, currentPosition: $currentPosition, _selectedLayerIds: $_selectedLayerIds, _selectedElementIds: $_selectedElementIds)';
  }
}
