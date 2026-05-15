part of '../surface_speakers_autolayout.dart';

class _WallSegment {
  final Offset start;
  final Offset end;
  final int index;

  const _WallSegment(this.start, this.end, this.index);

  double get length => (end - start).distance;
}
