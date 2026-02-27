// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import '../service/snap_service.dart';

class FusionSnapState {
  final Offset? cursorPosition;
  final SnapResult? snapResult;

  const FusionSnapState({
    this.cursorPosition,
    this.snapResult,
  });

  const FusionSnapState.initial() : cursorPosition = null, snapResult = null;

  /// Get the effective cursor position (snapped if applicable)
  Offset? get effectivePosition => snapResult?.snappedPosition ?? cursorPosition;

  /// Check if cursor is currently snapped
  bool get isSnapped => snapResult?.hasSnapped ?? false;

  FusionSnapState copyWith({
    Offset? cursorPosition,
    SnapResult? snapResult,
    bool clearCursorPosition = false,
    bool clearSnapResult = false,
  }) {
    return FusionSnapState(
      cursorPosition: clearCursorPosition ? null : cursorPosition ?? this.cursorPosition,
      snapResult: clearSnapResult ? null : snapResult ?? this.snapResult,
    );
  }

  @override
  bool operator ==(covariant FusionSnapState other) {
    if (identical(this, other)) return true;

    return other.cursorPosition == cursorPosition &&
        other.snapResult?.snappedPosition == snapResult?.snappedPosition &&
        other.snapResult?.hasSnapped == snapResult?.hasSnapped;
  }

  @override
  int get hashCode => cursorPosition.hashCode ^ (snapResult?.snappedPosition.hashCode ?? 0);
}
