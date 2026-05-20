part of '../surface_speakers_autolayout.dart';

class _BoundaryProjection {
  final Offset point;
  final int wallIndex;
  final double perimeterPosition;
  final double rotation;

  const _BoundaryProjection({
    required this.point,
    required this.wallIndex,
    required this.perimeterPosition,
    required this.rotation,
  });
}
