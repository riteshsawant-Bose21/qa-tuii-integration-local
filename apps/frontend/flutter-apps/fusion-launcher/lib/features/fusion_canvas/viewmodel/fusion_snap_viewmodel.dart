// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../service/snap_service.dart';
import '../state/fusion_snap_state.dart';

class FusionSnapViewModel extends Cubit<FusionSnapState> {
  FusionSnapViewModel() : super(const FusionSnapState.initial());

  final SnapService _snapService = SnapService();

  // Properties for snap context
  List<Offset> _polygonPoints = <Offset>[];
  final List<Offset> _toolPoints = <Offset>[];
  final double _currentScale = 1.0;

  /// Get current polygon points for comparison
  List<Offset> get polygonPoints => _polygonPoints;

  /// Update cursor position and calculate snap
  void updateCursorPosition(Offset? position) {
    if (position == null) {
      emit(const FusionSnapState.initial());
      return;
    }

    final SnapResult snapResult = _snapService.findSnapPoint(
      cursorPosition: position,
      existingPoints: <Offset>[
        ..._toolPoints,
        ..._polygonPoints,
      ],
      scale: _currentScale,
    );

    emit(
      FusionSnapState(
        cursorPosition: position,
        snapResult: snapResult,
      ),
    );
  }

  void addPolygonPoints(List<Offset> points) {
    // Only update if points have changed
    if (_arePointsEqual(_polygonPoints, points)) return;

    _polygonPoints = points.toList();
    if (state.cursorPosition != null) {
      updateCursorPosition(state.cursorPosition);
    }
  }

  bool _arePointsEqual(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void setToolPoints(List<Offset> points) {
    _toolPoints
      ..clear()
      ..addAll(points);
    if (state.cursorPosition != null) {
      updateCursorPosition(state.cursorPosition);
    }
  }
}
