// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../service/snap_service.dart';
import '../state/fusion_snap_state.dart';

class FusionSnapViewModel extends Cubit<FusionSnapState> {
  FusionSnapViewModel() : super(const FusionSnapState.initial());

  SnapService _snapService = SnapService();

  // Properties for snap context
  List<Offset> _existingPoints = <Offset>[];
  Offset? _activeStartPoint;
  double _currentScale = 1.0;

  /// Update cursor position and calculate snap
  void updateCursorPosition(Offset? position) {
    if (position == null) {
      emit(const FusionSnapState.initial());
      return;
    }

    final SnapResult snapResult = _snapService.findSnapPoint(
      cursorPosition: position,
      existingPoints: _existingPoints,
      activeStartPoint: _activeStartPoint,
      scale: _currentScale,
    );

    emit(
      FusionSnapState(
        cursorPosition: position,
        snapResult: snapResult,
      ),
    );
  }

  /// Update snap context for better snap point calculation
  void updateSnapContext({
    List<Offset>? existingPoints,
    Offset? activeStartPoint,
    double? scale,
    bool clearActiveStartPoint = false,
  }) {
    if (existingPoints != null) _existingPoints = existingPoints;
    if (clearActiveStartPoint) {
      _activeStartPoint = null;
    } else if (activeStartPoint != null) {
      _activeStartPoint = activeStartPoint;
    }
    if (scale != null) _currentScale = scale;

    // Refresh snapping with current cursor position
    if (state.cursorPosition != null) {
      updateCursorPosition(state.cursorPosition);
    }
  }

  /// Get snap service for external configuration
  SnapService get snapService => _snapService;

  /// Update snap service with new settings
  void updateSnapService(SnapService newSnapService) {
    _snapService = newSnapService;
    // Refresh snapping with current cursor position
    if (state.cursorPosition != null) {
      updateCursorPosition(state.cursorPosition);
    }
  }

  /// Clear active start point
  void clearActiveStartPoint() {
    _activeStartPoint = null;
    if (state.cursorPosition != null) {
      updateCursorPosition(state.cursorPosition);
    }
  }

  /// Set active start point for orthogonal snapping
  void setActiveStartPoint(Offset point) {
    _activeStartPoint = point;
    if (state.cursorPosition != null) {
      updateCursorPosition(state.cursorPosition);
    }
  }
}
