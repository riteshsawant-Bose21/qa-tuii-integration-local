// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../service/snap_service.dart';

class FusionSnapState {
  final Offset? cursorPosition;

  /// List of cursor positions for multi-point snapping (e.g., polygon dragging)
  final List<Offset>? cursorPositions;
  final SnapResult? snapResult;

  const FusionSnapState({
    this.cursorPosition,
    this.cursorPositions,
    this.snapResult,
  });

  const FusionSnapState.initial() : cursorPosition = null, cursorPositions = null, snapResult = null;

  /// Get the effective cursor position (snapped if applicable)
  Offset? get effectivePosition => snapResult?.snappedPosition ?? cursorPosition;

  /// Check if cursor is currently snapped
  bool get isSnapped => snapResult?.hasSnapped ?? false;

  FusionSnapState copyWith({
    Offset? cursorPosition,
    List<Offset>? cursorPositions,
    SnapResult? snapResult,
    bool clearCursorPosition = false,
    bool clearCursorPositions = false,
    bool clearSnapResult = false,
  }) {
    return FusionSnapState(
      cursorPosition: clearCursorPosition ? null : cursorPosition ?? this.cursorPosition,
      cursorPositions: clearCursorPositions ? null : cursorPositions ?? this.cursorPositions,
      snapResult: clearSnapResult ? null : snapResult ?? this.snapResult,
    );
  }

  @override
  bool operator ==(covariant FusionSnapState other) {
    if (identical(this, other)) return true;

    return other.cursorPosition == cursorPosition &&
        listEquals(other.cursorPositions, cursorPositions) &&
        other.snapResult?.snappedPosition == snapResult?.snappedPosition &&
        other.snapResult?.hasSnapped == snapResult?.hasSnapped &&
        other.snapResult?.cursorIndex == snapResult?.cursorIndex &&
        listEquals(other.snapResult?.snapPoints, snapResult?.snapPoints);
  }

  @override
  int get hashCode =>
      cursorPosition.hashCode ^ (cursorPositions?.hashCode ?? 0) ^ (snapResult?.snappedPosition.hashCode ?? 0) ^ (snapResult?.snapPoints.hashCode ?? 0);
}
