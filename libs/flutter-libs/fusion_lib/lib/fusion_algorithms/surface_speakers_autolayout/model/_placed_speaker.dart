part of '../surface_speakers_autolayout.dart';

class _PlacedSpeaker {
  final Offset point;
  final int wallIndex;
  final double perimeterPosition;

  /// Inward-facing rotation in degrees (angle of inward wall normal from +X axis).
  final double rotation;

  const _PlacedSpeaker({
    required this.point,
    required this.wallIndex,
    required this.perimeterPosition,
    required this.rotation,
  });
}
