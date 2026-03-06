import 'package:flutter/foundation.dart';

import '../fusion_tool_state.dart';

/// Base state for selection tool
abstract class SelectToolState extends FusionToolState {
  /// Set of selected layer IDs
  Set<String> get selectedLayerIds;

  /// Check if a layer is selected
  bool isLayerSelected(String? layerId) => layerId != null && selectedLayerIds.contains(layerId);
}

/// Idle state - no active selection operation
class IdleSelectToolState extends SelectToolState {
  final Set<String> _selectedLayerIds;

  IdleSelectToolState({Set<String>? selectedLayerIds}) : _selectedLayerIds = selectedLayerIds ?? <String>{};

  @override
  Set<String> get selectedLayerIds => _selectedLayerIds;

  IdleSelectToolState copyWith({Set<String>? selectedLayerIds}) {
    return IdleSelectToolState(selectedLayerIds: selectedLayerIds ?? _selectedLayerIds);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IdleSelectToolState && setEquals(other._selectedLayerIds, _selectedLayerIds);
  }

  @override
  int get hashCode => _selectedLayerIds.hashCode;
}
